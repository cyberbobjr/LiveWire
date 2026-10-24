-- Targeted regression tests in the real 42.21 world. Test cache only.
local H = { server = {}, client = {} }
local lines, allOK = {}, true
local S = {}
local function rec(ok, name, detail)
    if not ok then allOK = false end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. " - " .. tostring(detail or "")
end
local function check(name, fn)
    local ok, value, detail = pcall(fn)
    rec(ok and value == true, name, ok and detail or value)
end
local function result()
    local pass = 0
    for i = 1, #lines do if lines[i]:sub(1,4) == "PASS" then pass = pass + 1 end end
    return {ok=allOK, summary=pass .. "/" .. #lines .. " PASS", lines=lines}
end
local function place(sq, sprite)
    local props = ISMoveableSpriteProps.new(getSprite(sprite))
    props:placeMoveableInternal(S.player, sq, props:instanceItem(sprite), sprite)
    local objs = sq:getObjects()
    for i = objs:size()-1, 0, -1 do
        local o=objs:get(i)
        if o:getSprite() and o:getSprite():getName()==sprite then return o end
    end
end
local function device(obj)
    local m = LiveWire.Marks.get(obj)
    return m and LiveWire.Registry.device(m.id)
end
local function barrel(sq)
    local o=IsoThumpable.new(getCell(),sq,"carpentry_02_54",false)
    local fc=ComponentType.FluidContainer:CreateComponent()
    fc:setCapacity(100)
    GameEntityFactory.AddComponent(o,true,fc)
    sq:AddSpecialObject(o)
    o:getFluidContainer():addFluid(Fluid.Water,50)
    if isServer() then o:transmitCompleteItemToClients() end
    return o
end
local function authorityStart(player)
    S.player=player
    S.errors=getLuaDebuggerErrorCount()
    local R=LiveWire.Registry
    check("runtime target 42.21",function()
        local version=tostring(getCore():getVersionNumber())
        return string.find(version,"42.21",1,true)~=nil,version
    end)
    player:setPerkLevelDebug(Perks.Electricity,10)
    local origin=player:getCurrentSquare()
    local fixture,fs
    for x=origin:getX()-18,origin:getX()+18 do
        for y=origin:getY()-18,origin:getY()+18 do
            local sq=getCell():getGridSquare(x,y,origin:getZ())
            if sq and sq:getRoom() then
                local objs=sq:getObjects()
                for i=0,objs:size()-1 do
                    local o=objs:get(i)
                    local sp=o:getSprite()
                    if not fixture and sp and sp:getProperties():has(IsoFlagType.waterPiped) then
                        fixture,fs=o,sq
                    end
                end
            end
        end
    end
    if not fixture then return false,"no indoor fixture" end
    S.fixture=fixture
    S.inv=place(origin,"batman_livewire_01_12")
    S.wind=place(origin,"batman_livewire_01_4")
    S.pump=place(fs,"batman_livewire_01_72")
    S.grid=R.grid(device(S.inv).grid)
    S.pdev=device(S.pump)
    R.link(S.pdev,S.grid)
    R.link(device(S.wind),S.grid)
    S.barrel=barrel(fs)
    LiveWire.Pump.linkBarrel(S.pdev,S.barrel)
    local water=getSandboxOptions():getOptionByName("WaterShutModifier")
    S.water,S.waterSaved=water,water:getValue()
    water:setValue(0)
    S.grid.powered=true
    check("C06 index reflects placement and movement",function()
        local d=R.addDevice({role="source",model="SolarPanel",x=-1,y=8,z=0})
        local n=#R.devicesInChunk(-1,1)
        R.moveDevice(d,-17,8,0)
        local ok=n==1 and #R.devicesInChunk(-1,1)==0 and #R.devicesInChunk(-3,1)==1
        R.removeDevice(d.id)
        return ok and #R.devicesInChunk(-3,1)==0
    end)
    check("C07 legacy barrel mark migrated; moved mark cleared",function()
        local D=LiveWire.Defs
        S.barrel:getModData()[D.BARREL_KEY]={pump=S.pdev.id}
        local m=LiveWire.Install.barrelMark(S.barrel)
        local migrated=m and m.x==fs:getX()
        local sq=getCell():getGridSquare(fs:getX()+1,fs:getY(),fs:getZ())
        local moved=barrel(sq)
        moved:getModData()[D.BARREL_KEY]={pump=S.pdev.id,x=fs:getX(),y=fs:getY(),z=fs:getZ()}
        local cleared=LiveWire.Install.barrelMark(moved)==nil and moved:getModData()[D.BARREL_KEY]==nil
        sq:transmitRemoveItemFromSquare(moved)
        return migrated and cleared
    end)
    check("C22 inspection does not engage brake; explicit brake reversible",function()
        local d=device(S.wind)
        local inspect=LWInspectAction:new(player,S.wind):complete()
        local untouched=d.brake~=true
        LiveWire.Commands.handle(player,LiveWire.Protocol.C_SET_BRAKE,{device=d.id,brake=true})
        local on=d.brake==true and LiveWire.Marks.get(S.wind).br==true
        LiveWire.Commands.handle(player,LiveWire.Protocol.C_SET_BRAKE,{device=d.id,brake=false})
        return inspect and untouched and on and d.brake==false and LiveWire.Marks.get(S.wind).br==false
    end)
    S.gen=IsoGenerator.new(instanceItem("Base.Generator"),getCell(),origin)
    if S.gen:getObjectIndex()==-1 then origin:AddSpecialObject(S.gen) end
    if isServer() then S.gen:transmitCompleteItemToClients() end
    S.gen:setConnected(true); S.gen:setFuel(50)
    S.backup=LiveWire.Backup.register(S.gen,S.grid)
    check("C09 manual stop/start respected; restore preserves manual stop",function()
        local B,d,g=LiveWire.Backup,S.backup,S.gen
        B.step(d,0.01,1/60)
        local started=g:isActivated()
        g:setActivated(false)
        local w=B.step(d,0.01,1/60)
        B.restore(d)
        local stopped=not g:isActivated() and d.manual and w==0
        g:setActivated(true)
        B.step(d,0.99,1/60)
        local manualOn=g:isActivated() and d.state=="manual"
        g:setActivated(false)
        B.step(d,0.01,1/60)
        return started and stopped and manualOn and not g:isActivated()
    end)
    check("C09 explicit automatic resume",function()
        LiveWire.Commands.handle(player,LiveWire.Protocol.C_RESUME_BACKUP,{device=S.backup.id})
        LiveWire.Backup.step(S.backup,0.01,1/60)
        local good=not S.backup.manual and S.gen:isActivated()
        S.gen:setActivated(false)
        LiveWire.Backup.step(S.backup,0.01,1/60)
        return good
    end)
    check("C23 hourly purge keeps active daily XP cooldown",function()
        LiveWire.Xp.awardLimited(player,"fixes:daily",1,24)
        LiveWire.Xp.purge()
        return not LiveWire.Xp.awardLimited(player,"fixes:daily",1,24)
    end)
    check("C05 loaded fridge food aged before power cut",function()
        local fridge,cont
        for x=origin:getX()-14,origin:getX()+14 do
            for y=origin:getY()-14,origin:getY()+14 do
                local dx,dy=x-origin:getX(),y-origin:getY()
                local sq=dx*dx+dy*dy<=196 and getCell():getGridSquare(x,y,origin:getZ())
                local objs=sq and sq:getObjects()
                if objs then
                    for i=0,objs:size()-1 do
                        local c=objs:get(i):getContainerByType("fridge")
                        if not fridge and c then fridge,cont=objs:get(i),c end
                    end
                end
            end
        end
        if not fridge then return false,"no loaded fridge near the inverter" end
        local inv=device(S.inv)
        local a={x=inv.x,y=inv.y,z=inv.z}
        LiveWire.Anchor.rememberSquare(fridge:getSquare())
        LiveWire.Anchor.set(inv.id,a,true)
        local food=cont:AddItem("Base.Apple")
        if not food then return false,"apple creation failed" end
        local now=getGameTime():getWorldAgeHours()
        food:setAge(0);food:setLastAged(now-2)
        local before=fridge:getSquare():haveElectricity()
        LiveWire.Anchor.set(inv.id,a,false)
        local aged=food:getLastAged()==now and food:getAge()<2/24
        LiveWire.Anchor.set(inv.id,a,true)
        return before and aged,"aged=" .. food:getAge()
    end)
    if not isServer() then
        check("C16 solo snapshot reused then invalidated",function()
            local a=LiveWire.Client.snapshot(device(S.inv).id)
            local b=LiveWire.Client.snapshot(device(S.inv).id)
            S.grid.rev=(S.grid.rev or 0)+1
            return a==b and LiveWire.Client.snapshot(device(S.inv).id)~=a
        end)
    end
    -- Let the real OnTick queue discover the fixture, no synchronous drain here.
    S.pumpStarted=getTimestampMs()
    S.stage="discovery"
    S.ticks=0
    Events.OnTick.Add(function() S.ticks=S.ticks+1 end)
    return true
end
local function authorityDone()
    if S.finished then return true end
    if S.stage=="discovery" then
        local src=IsoObject.FindExternalWaterSource(S.fixture:getSquare())
        if not src and getTimestampMs()-S.pumpStarted<25000 then return false end
        check("C04 pump discovers fixture across real ticks",function()
            return src~=nil and LiveWire.Install.isRelay(src) and S.ticks>1,"ticks=" .. S.ticks
        end)
        check("C04 real pump transfers water after discovery",function()
            S.grid.powered=true; device(S.inv).state="on"
            local before=S.barrel:getFluidContainer():getAmount()
            LiveWire.Pump.step(S.pdev)
            return S.barrel:getFluidContainer():getAmount()<before
        end)
        if isServer() then
            sendServerCommand(S.player,"LWFixTest","scene",{wind=device(S.wind).id,
                backup=S.backup.id,x=device(S.pump).x,y=device(S.pump).y,z=device(S.pump).z,pump=S.pdev.id})
            S.stage="network"; S.networkAt=getTimestampMs()
            return false
        end
        S.stage="end"
    end
    if S.stage=="network" then
        if not S.safeChecked and tostring(S.player:getRole():getName()):lower()=="user" then
            S.safeChecked=true
            local sq=S.player:getCurrentSquare()
            local sh=SafeHouse.addSafeHouse(sq:getX()-1,sq:getY()-1,3,3,"pzat_other_owner")
            check("C22 non-admin denied inspection, snow clearing and brake in foreign safehouse",function()
                local d=device(S.wind)
                d.snow=1
                local inspect=LWInspectAction:new(S.player,S.wind):complete()
                local snow=LWClearSnowAction:new(S.player,S.wind):complete()
                local previous=d.brake
                LiveWire.Commands.handle(S.player,LiveWire.Protocol.C_SET_BRAKE,{device=d.id,brake=not previous})
                local good=inspect==false and snow==false and d.snow==1 and d.brake==previous
                d.snow=nil
                return good
            end)
            SafeHouse.removeSafeHouse(sh)
        end
        if not S.clientDone and getTimestampMs()-S.networkAt<45000 then return false end
        rec(S.clientDone==true,"MP client completed real command round trips")
        rec(S.safeChecked==true,"MP authority observed regular user role")
        S.stage="end"
    end
    if S.stage=="end" then
        if S.water then S.water:setValue(S.waterSaved) end
        rec(getLuaDebuggerErrorCount()==S.errors,"no new Lua errors on authority",
            getLuaDebuggerErrorCount()-S.errors)
        S.finished=true
        return true
    end
    return false
end
function H.server.start(ctx)
    Events.OnClientCommand.Add(function(module,command)
        if module=="LWFixTest" and command=="done" then S.clientDone=true end
    end)
    return authorityStart(ctx.players()[1])
end
H.server.done=authorityDone
H.server.result=result

function H.client.start(ctx)
    if not isClient() then return authorityStart(getPlayer()) end
    S.errors=getLuaDebuggerErrorCount()
    S.clientAt=getTimestampMs()
    Events.OnServerCommand.Add(function(module,command,args)
        if module=="LWFixTest" and command=="scene" then S.scene=args; S.stage="brakeOn" end
    end)
    return true
end
function H.client.done()
    if not isClient() then return authorityDone() end
    if S.finished then return true end
    if getTimestampMs()-S.clientAt>90000 then
        rec(false,"MP command round trips timed out",S.stage);S.finished=true;return true
    end
    local scene=S.scene
    if not scene then return false end
    local ps=getPlayer():getCurrentSquare()
    local objs=ps:getObjects()
    local wind
    for i=0,objs:size()-1 do
        local m=LiveWire.Marks.get(objs:get(i))
        if m and m.id==scene.wind then wind=m end
    end
    if not wind then return false end
    if S.stage=="brakeOn" then
        SendCommandToServer("/setaccesslevel " .. getPlayer():getUsername() .. " user")
        S.stage="role"
    elseif S.stage=="role" then
        if tostring(getPlayer():getRole():getName()):lower()~="user" then return false end
        rec(true,"MP commands tested as a regular user")
        LiveWire.Client.send(LiveWire.Protocol.C_SET_BRAKE,{device=scene.wind,brake=true})
        S.stage="waitOn"
    elseif S.stage=="waitOn" and wind.br==true then
        rec(true,"MP brake command and mark synchronized")
        LiveWire.Client.send(LiveWire.Protocol.C_SET_BRAKE,{device=scene.wind,brake=false})
        S.stage="waitOff"
    elseif S.stage=="waitOff" and wind.br==false then
        rec(true,"MP brake release synchronized")
        LiveWire.Client.send(LiveWire.Protocol.C_RESUME_BACKUP,{device=scene.backup})
        S.stage="resume";S.resumeAt=getTimestampMs()
    elseif S.stage=="resume" and getTimestampMs()-S.resumeAt>1500 then
        local mark
        for i=0,objs:size()-1 do
            local m=objs:get(i):getModData()[LiveWire.Defs.BACKUP_KEY]
            if m and m.id==scene.backup then mark=m end
        end
        if not mark or mark.manual~=false then return false end
        rec(true,"MP automatic backup resume synchronized")
        local pumpSq=getCell():getGridSquare(scene.x,scene.y,scene.z)
        local pump=pumpSq and LiveWire.Marks.findOnSquare(pumpSq,scene.pump)
        if not pump then return false end
        LiveWire.PumpView.show(pump)
        S.stage="view"; S.viewAt=getTimestampMs()
    elseif S.stage=="view" then
        if LiveWire.PumpView.job or LiveWire.PumpView.dirty then return false end
        rec(#LiveWire.PumpView.fixtures>0,"MP pump view discovers fixtures asynchronously",
            #LiveWire.PumpView.fixtures)
        LiveWire.PumpView.hide()
        rec(getLuaDebuggerErrorCount()==S.errors,"no new client Lua errors")
        sendClientCommand(getPlayer(),"LWFixTest","done",{})
        S.finished=true
        return true
    end
    return false
end
H.client.result=result
return H
