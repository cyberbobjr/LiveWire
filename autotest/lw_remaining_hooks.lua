-- Remaining CXX fixes, real 42.21 SP / dedicated server + two observing clients.
-- Only private test copies are changed. Historical timestamps are test inputs.
local H={server={},client={}}
local S,C={},{}
local lines,allOK={},true
local function rec(ok,name,detail)
    if not ok then allOK=false end
    lines[#lines+1]=(ok and "PASS " or "FAIL ")..name.." - "..tostring(detail or "")
end
local function check(name,fn)
    local ok,value,detail=pcall(fn)
    rec(ok and value==true,name,ok and detail or value)
end
local function result()
    local pass=0
    for i=1,#lines do if lines[i]:sub(1,4)=="PASS" then pass=pass+1 end end
    return {ok=allOK,summary=pass.."/"..#lines.." PASS",lines=lines}
end
local function device(obj)
    local m=LiveWire.Marks.get(obj)
    return m and LiveWire.Registry.device(m.id)
end
local function square(x,y,z) return getCell():getGridSquare(x,y,z) end
local function place(sq,name)
    local props=ISMoveableSpriteProps.new(getSprite(name))
    return props:placeMoveableInternal(S.player,sq,props:instanceItem(name),name)
end
local function barrel(sq)
    local o=IsoThumpable.new(getCell(),sq,"carpentry_02_54",false)
    local fc=ComponentType.FluidContainer:CreateComponent()
    fc:setCapacity(100);GameEntityFactory.AddComponent(o,true,fc)
    sq:AddSpecialObject(o);fc:addFluid(Fluid.Water,75)
    if isServer() then o:transmitCompleteItemToClients() end
    return o
end
local function setWater(obj,n)
    local fc=obj:getFluidContainer()
    fc:removeFluid(fc:getAmount());fc:addFluid(Fluid.Water,n);obj:sync()
end
local function seen(label)
    local n=0
    for _ in pairs(S.seen[label] or {}) do n=n+1 end
    return n>=S.observers
end
local function report(label)
    if isClient() then sendClientCommand(getPlayer(),"LWRemaining","seen",{label=label})
    else S.seen[label]={solo=true} end
end
local function notify(command)
    if isServer() then
        for i,p in ipairs(S.ctx.players()) do
            local args={}
            for k,v in pairs(S.scene) do args[k]=v end
            local target=S.targets and S.targets[p:getUsername()]
            if target then args.ax,args.ay,args.az=target.x,target.y,target.z end
            sendServerCommand(p,"LWRemaining",command,args)
        end
    else C.command,C.scene=command,S.scene end
end
local function relayScene(scene)
    local sq=square(scene.rx,scene.ry,scene.rz)
    if not sq then return nil end
    local objects=sq:getObjects()
    for i=0,objects:size()-1 do
        if LiveWire.Install.isRelay(objects:get(i)) then return objects:get(i) end
    end
end
local function makeOrphans()
    local dev={id="remaining_orphan",relays={}}
    for _,z in ipairs({-2,9}) do LiveWire.Pump.placeRelay(dev,S.scene.ox,S.scene.oy,z) end
end
local function authorityCases()
    local R,P=LiveWire.Registry,LiveWire.Pump
    local origin=S.player:getCurrentSquare()
    check("C17 real generator uses normalized hysteresis and snapshot",function()
        local opts=getSandboxOptions()
        local startOpt=opts:getOptionByName("LiveWire.BackupStartPercent")
        local stopOpt=opts:getOptionByName("LiveWire.BackupStopPercent")
        local oldStart,oldStop=startOpt:getValue(),stopOpt:getValue()
        startOpt:setValue(80);stopOpt:setValue(20)
        local gen=IsoGenerator.new(instanceItem("Base.Generator_Old"),getCell(),origin)
        gen:setConnected(true);gen:setFuel(10)
        local dev=LiveWire.Backup.register(gen,S.grid)
        local a=LiveWire.Backup.step(dev,0.79,1/60)>0 and gen:isActivated()
        local b=LiveWire.Backup.step(dev,0.82,1/60)>0 and gen:isActivated()
        local c=LiveWire.Backup.step(dev,0.85,1/60)==0 and not gen:isActivated()
        local snap=LiveWire.Sim.snapshot(S.grid)
        startOpt:setValue(oldStart);stopOpt:setValue(oldStop)
        LiveWire.Backup.forget(dev)
        return a and b and c and math.abs(snap.backup.stop-85)<0.001
    end)
    check("C24 lost or altered mark repaired without duplicate adoption",function()
        local obj=place(origin,"batman_livewire_01_0")
        local dev=device(obj)
        dev.cond,dev.eff=64,0.9
        obj:getModData().movableData.LiveWire=nil
        local ok=LiveWire.Devices.validate(dev)
        local m=LiveWire.Marks.get(obj)
        m.eff,m.cond=1,100
        local adopted=LiveWire.Devices.adoptSquare(S.player,origin)
        m=LiveWire.Marks.get(obj)
        S.scene.panel=dev.id
        return ok and adopted==0 and m.id==dev.id and m.eff==0.9 and m.cond==64
    end)
    check("C24 truly destroyed tile removed from registry",function()
        local obj=place(origin,"batman_livewire_01_8")
        local dev=device(obj)
        origin:transmitRemoveItemFromSquare(obj)
        return not LiveWire.Devices.validate(dev) and not R.device(dev.id)
    end)
    check("C21 unloaded network exhausts stock inside the hour",function()
        local now=getGameTime():getWorldAgeHours()
        local inv=R.addDevice({role="inverter",model="Inverter",x=origin:getX()+1000,
            y=origin:getY()+1000,z=0,cond=100,eff=1,level=0,state="on"})
        local g=R.createGrid(inv)
        local bank=R.addDevice({role="storage",model="PowerBank",x=inv.x+1,y=inv.y,z=0,
            cond=100,level=0,slots={{id=9999,model="Base.CarBattery2",charge=0.5,cond=100,cycles=0}}})
        R.link(bank,g);g.demand=980;g.lastTick=now-1;g.powered=true
        LiveWire.PowerHistory.record(R.data,inv,true,now-1)
        LiveWire.Sim.stepGrid(g,now,{clouds=1,windKph=0,snowing=false,temp=20,dawn=6,dusk=20,month=6})
        local log=R.data.powerHistory[inv.id].log
        S.scene.probe=inv.id;S.scene.cut=log[#log].t
        return not g.powered and g.stock<0.000001 and #log==2
            and math.abs(log[2].t-(now-0.7))<0.00001,log[#log].t
    end)
    check("C12 real food replays forty power transitions",function()
        local fridge
        for x=origin:getX()-15,origin:getX()+15 do
            for y=origin:getY()-15,origin:getY()+15 do
                local sq=square(x,y,origin:getZ())
                if sq then
                    local objects=sq:getObjects()
                    for i=0,objects:size()-1 do
                        local cont=objects:get(i):getContainerByType("fridge")
                        if not fridge and cont then fridge={obj=objects:get(i),cont=cont,sq=sq} end
                    end
                end
            end
        end
        if not fridge then return false,"no real fridge" end
        local opts=getSandboxOptions()
        opts:getOptionByName("ElecShutModifier"):setValue(-1)
        opts:getOptionByName("FridgeFactor"):setValue(3)
        opts:getOptionByName("FoodRotSpeed"):setValue(3)
        local now=getGameTime():getWorldAgeHours()
        local span=math.min(4,now)
        if span<=0 then return false,"world age must be positive" end
        local inv={id="remaining_food",x=fridge.sq:getX(),y=fridge.sq:getY(),z=fridge.sq:getZ()}
        local log={}
        for i=0,39 do
            local t=now-span+i*span/40
            LiveWire.PowerHistory.record(R.data,inv,i%2==0,t)
            if i>=24 then log[#log+1]={t=t,on=i%2==0} end
        end
        R.anchors[inv.id]={x=inv.x,y=inv.y,z=inv.z,on=false,log=log,log0=false}
        local food=fridge.cont:AddItem("Base.Apple")
        food:setAge(0);food:setFreezingTime(0);food:setFrozen(false);food:setLastAged(now-span)
        local n=LiveWire.FridgeCatchup.onLoadChunk(fridge.sq:getChunk())
        -- As with a reloaded chunk, serialize the food AFTER authority catch-up.
        -- Vanilla ItemStats carries freezing flags but does not carry food age.
        if isServer() then sendAddItemToContainer(fridge.cont,food) end
        local expected=span*0.6/24
        S.scene.fx,S.scene.fy,S.scene.fz=inv.x,inv.y,inv.z
        S.scene.food,S.scene.age=food:getID(),food:getAge()
        S.scene.history=#R.data.powerHistory[inv.id].log
        return n>=1 and S.scene.history==40 and #R.anchors[inv.id].log==16
            and math.abs(food:getAge()-expected)<0.00001,food:getAge().." expected="..expected
    end)
    check("C19 native chunk cleanup visits floors -2 and 9",function()
        makeOrphans()
        local lo=P.findRelay(S.scene.ox,S.scene.oy,-2)
        local hi=P.findRelay(S.scene.ox,S.scene.oy,9)
        if not lo or not hi then return false,"could not create extreme-level relays" end
        local chunk=lo:getSquare():getChunk()
        P.onLoadChunk(chunk)
        return not P.findRelay(S.scene.ox,S.scene.oy,-2) and not P.findRelay(S.scene.ox,S.scene.oy,9),
            chunk:getMinLevel()..".."..chunk:getMaxLevel()
    end)
    S.targets={}
    local players=isServer() and S.ctx.players() or {S.player}
    for i,p in ipairs(players) do
        p:setPerkLevelDebug(Perks.Electricity,i==1 and 10 or 0)
        local sq=square(origin:getX()+i,origin:getY()+2,origin:getZ())
        local obj=IsoObject.new(getCell(),sq,"batman_livewire_01_0")
        sq:transmitAddObjectToSquare(obj,-1)
        S.targets[p:getUsername()]={x=sq:getX(),y=sq:getY(),z=sq:getZ()}
        if not isServer() then
            LiveWire.Commands.handle(p,LiveWire.Protocol.C_ADOPT,S.targets[p:getUsername()])
        end
    end
end
local function authorityStart(ctx)
    S.ctx,S.seen,S.started=ctx,{},getTimestampMs()
    S.player=isServer() and ctx.players()[1] or getPlayer()
    S.observers=isServer() and #ctx.players() or 1
    S.phase=ctx.params.phase
    S.errors=getLuaDebuggerErrorCount()
    rec(tostring(getCore():getVersionNumber())=="42.21","runtime 42.21")
    -- Control each service deterministically; native discovery ticks stay active.
    Events.EveryOneMinute.Remove(LiveWire.Pump.tickMinute)
    Events.EveryTenMinutes.Remove(LiveWire.Sim.tick)
    S.scene=ModData.getOrCreate("LiveWireRemainingTest")
    local R=LiveWire.Registry
    if S.phase=="reload" then
        if isServer() then
            rec(getSandboxOptions():getOptionByName("WaterShutModifier"):getValue()==0,
                "test sandbox settings preserved across dedicated-server restart")
        end
        check("C12 private history survives real process restart",function()
            local h=R.data.powerHistory.remaining_food
            return h and #h.log==S.scene.history and #R.anchors.remaining_food.log==16
        end)
        check("C21 exact cut time survives restart",function()
            local h=R.data.powerHistory[S.scene.probe]
            return h and math.abs(h.log[#h.log].t-S.scene.cut)<0.00001
        end)
        check("C19 saved orphan relays cleaned by real LoadChunk",function()
            return not LiveWire.Pump.findRelay(S.scene.ox,S.scene.oy,-2)
                and not LiveWire.Pump.findRelay(S.scene.ox,S.scene.oy,9)
        end)
        check("C23 saved global measurement budget cannot reset at restart",function()
            local count=0
            for _,entries in pairs(R.data.measureXp or {}) do if #entries==5 then count=count+1 end end
            return count>=1,count
        end)
        check("C08 relay ownership and water survive restart",function()
            local relay=relayScene(S.scene)
            return relay and relay:getModData()[LiveWire.Defs.RELAY_KEY].pump==S.scene.near
                and math.abs(relay:getFluidContainer():getAmount()-S.scene.litres)<0.001,
                relay and (relay:getModData()[LiveWire.Defs.RELAY_KEY].pump.." litres="
                    ..relay:getFluidContainer():getAmount()) or "missing relay"
        end)
        notify("reload");S.stage="reloadSeen"
        if not isServer() then report("reload") end
        return true
    end
    S.player:setPerkLevelDebug(Perks.Electricity,10)
    local origin=S.player:getCurrentSquare()
    S.scene.ox,S.scene.oy,S.scene.oz=origin:getX(),origin:getY(),origin:getZ()
    local fixture,fs
    for x=origin:getX()-16,origin:getX()+16 do
        for y=origin:getY()-16,origin:getY()+16 do
            local sq=square(x,y,origin:getZ())
            if sq and sq:getRoom() and not IsoObject.FindExternalWaterSource(sq) then
                local objects=sq:getObjects()
                for i=0,objects:size()-1 do
                    local o=objects:get(i)
                    if not fixture and o:getSprite() and o:getSprite():getProperties():has(IsoFlagType.waterPiped)
                        and square(x+4,y,origin:getZ()) and square(x+1,y,origin:getZ()) then fixture,fs=o,sq end
                end
            end
        end
    end
    if not fixture then return false,"no indoor fixture without an external water source" end
    S.fixture,S.fs=fixture,fs
    local inv=place(origin,"batman_livewire_01_12")
    S.grid=R.grid(device(inv).grid)
    S.scene.inverter=device(inv).id
    S.far=device(place(square(fs:getX()+4,fs:getY(),fs:getZ()),"batman_livewire_01_72"))
    R.link(S.far,S.grid)
    S.farBarrel=barrel(square(S.far.x,S.far.y,S.far.z))
    getSandboxOptions():getOptionByName("WaterShutModifier"):setValue(0)
    S.grid.powered=true
    LiveWire.Pump.linkBarrel(S.far,S.farBarrel)
    S.stage="far";S.stageAt=getTimestampMs()
    return true
end
local function finishAuthority()
    if S.phase=="create" then
        check("C23 real measurements capped globally at five base awards",function()
            local p=S.player
            p:setPerkLevelDebug(Perks.Electricity,1)
            p:getXp():setXPToLevel(Perks.Electricity,1)
            p:getInventory():AddItem("LiveWire.VoltageTester")
            local sq=p:getCurrentSquare()
            local before=p:getXp():getXP(Perks.Electricity)
            local calls=0
            for dx=-1,1 do
                for dy=-1,1 do
                    if calls<5 then
                        local target=square(sq:getX()+dx,sq:getY()+dy,sq:getZ())
                        if target and LWMeasureAction:new(p,target):complete() then calls=calls+1 end
                    end
                end
            end
            local five=p:getXp():getXP(Perks.Electricity)
            LWMeasureAction:new(p,square(sq:getX()+2,sq:getY(),sq:getZ())):complete()
            local six=p:getXp():getXP(Perks.Electricity)
            S.scene.xp=p:getUsername()
            return calls==5 and five>before and five==six,
                "before="..before.." five="..five.." six="..six
        end)
        makeOrphans() -- persisted on disk, cleaned by native LoadChunk next process
        S.scene.litres=relayScene(S.scene):getFluidContainer():getAmount()
        -- Isolate persistence from legitimate pumping before the next hooks start.
        S.grid.powered=false
        local inv=LiveWire.Registry.device(S.scene.inverter)
        inv.state="off";LiveWire.Devices.syncMark(inv)
        if isServer() then getSandboxOptions():saveServerLuaFile(getServerName()) end
    end
    rec(getLuaDebuggerErrorCount()==S.errors,"no new authority Lua errors",getLuaDebuggerErrorCount()-S.errors)
    S.finished=true
    return true
end
local function authorityDone()
    if S.finished then return true end
    if getTimestampMs()-S.started>170000 then
        rec(false,"authority scenario timed out",S.stage);return finishAuthority()
    end
    local P,R=LiveWire.Pump,LiveWire.Registry
    if S.stage=="far" then
        local relay=IsoObject.FindExternalWaterSource(S.fs)
        if not relay then return false end
        check("C08 first pump discovers a real tap",function()
            return LiveWire.Install.isRelay(relay) and relay:getModData()[LiveWire.Defs.RELAY_KEY].pump==S.far.id
        end)
        setWater(relay,7.25)
        S.relay=relay
        local sq=relay:getSquare()
        S.scene.rx,S.scene.ry,S.scene.rz=sq:getX(),sq:getY(),sq:getZ()
        S.near=device(place(square(S.fs:getX()+1,S.fs:getY(),S.fs:getZ()),"batman_livewire_01_72"))
        S.scene.near,S.scene.far=S.near.id,S.far.id
        R.link(S.near,S.grid)
        S.nearBarrel=barrel(square(S.near.x,S.near.y,S.near.z))
        P.linkBarrel(S.near,S.nearBarrel)
        S.stage="near";S.stageAt=getTimestampMs()
        return false
    elseif S.stage=="near" then
        if S.relay:getModData()[LiveWire.Defs.RELAY_KEY].pump~=S.near.id then return false end
        check("C08 closer pump takes ownership without losing water",function()
            for i=1,3 do P.maintain(S.far);P.maintain(S.near) end
            local key=LiveWire.posKey(S.scene.rx,S.scene.ry,S.scene.rz)
            return S.near.relays[key] and not S.far.relays[key]
                and math.abs(S.relay:getFluidContainer():getAmount()-7.25)<0.001
        end)
        check("C18 idle pump cannot accumulate a burst of flow",function()
            for _,pos in pairs(S.near.relays) do
                local o=P.findRelay(pos.x,pos.y,pos.z)
                if o then setWater(o,LiveWire.Defs.RELAY_LITRES) end
            end
            S.near.budget=10;S.grid.powered=true
            for i=1,10 do P.step(S.near) end
            local idle=S.near.budget==0
            setWater(S.relay,15)
            local before=S.nearBarrel:getFluidContainer():getAmount()
            P.step(S.near)
            return idle and math.abs(S.relay:getFluidContainer():getAmount()-20)<0.001
                and math.abs(before-S.nearBarrel:getFluidContainer():getAmount()-5)<0.001
        end)
        check("C08 disconnect transfers the same tank back to the remaining pump",function()
            local keys={}
            for key in pairs(S.near.barrels) do keys[#keys+1]=key end
            for i=1,#keys do P.unlinkBarrel(S.near,keys[i]) end
            local ok=S.relay:getModData()[LiveWire.Defs.RELAY_KEY].pump==S.far.id
                and math.abs(S.relay:getFluidContainer():getAmount()-20)<0.001
            P.linkBarrel(S.near,S.nearBarrel);P.maintain(S.near)
            return ok and S.relay:getModData()[LiveWire.Defs.RELAY_KEY].pump==S.near.id
        end)
        authorityCases()
        S.stage="observers";notify("create")
        if not isServer() then
            rec(true,"C24 adoption command executed in SP")
            report("create")
        end
        return false
    elseif S.stage=="observers" and seen("create") then
        check("C24 adoption is independent of reporting player's level",function()
            for _,pos in pairs(S.targets) do
                local list=R.devicesAt(pos.x,pos.y,pos.z)
                local adopted
                for i=1,#list do if list[i].model=="SolarPanel" then adopted=list[i] end end
                if not adopted or adopted.eff~=0.85 or adopted.level~=0 then return false end
            end
            return true
        end)
        return finishAuthority()
    elseif S.stage=="reloadSeen" and seen("reload") then
        return finishAuthority()
    end
    return false
end
function H.server.start(ctx)
    Events.OnClientCommand.Add(function(module,command,p,args)
        if module=="LWRemaining" and command=="seen" then
            S.seen[args.label]=S.seen[args.label] or {}
            S.seen[args.label][p:getUsername()]=true
        end
    end)
    return authorityStart(ctx)
end
H.server.done=authorityDone
H.server.result=result
function H.client.start(ctx)
    if not isClient() then return authorityStart(ctx) end
    C.errors,C.started=getLuaDebuggerErrorCount(),getTimestampMs()
    Events.OnServerCommand.Add(function(module,command,args)
        if module=="LWRemaining" then C.command,C.scene=command,args end
    end)
    return true
end
function H.client.done()
    if not isClient() then return authorityDone() end
    if C.finished then return true end
    if getTimestampMs()-C.started>190000 then
        rec(false,"client observer timed out",C.command);C.finished=true;return true
    end
    local scene=C.scene
    if not scene then return false end
    local relay=relayScene(scene)
    local mark=relay and relay:getModData()[LiveWire.Defs.RELAY_KEY]
    if not mark or mark.pump~=scene.near then return false end
    if not C.observed then
        rec(true,"C08 relay ownership synchronized to this client")
        rec(math.abs(relay:getFluidContainer():getAmount()-(C.command=="reload" and scene.litres or 20))<0.01,
            "C08/C18 relay water synchronized",relay:getFluidContainer():getAmount())
        C.observed=true
    end
    if C.command=="create" then
        if not C.demoted then
            SendCommandToServer("/setaccesslevel "..getPlayer():getUsername().." user")
            C.demoted=true;return false
        end
        if tostring(getPlayer():getRole():getName()):lower()~="user" then return false end
        local sq=square(scene.ax,scene.ay,scene.az)
        local obj=sq and LiveWire.Marks.firstOnSquare(sq)
        if not C.adoptSent then
            rec(true,"C24 command issued as a regular MP user")
            LiveWire.Client.send(LiveWire.Protocol.C_ADOPT,{x=scene.ax,y=scene.ay,z=scene.az})
            C.adoptSent=true;return false
        end
        local m=obj and LiveWire.Marks.get(obj)
        if not m or m.eff~=0.85 then return false end
        rec(m.level==0,"C24 fixed adoption efficiency synchronized",m.eff)
        local fs=square(scene.fx,scene.fy,scene.fz)
        local food
        if fs then
            local objects=fs:getObjects()
            for i=0,objects:size()-1 do
                local cont=objects:get(i):getContainerByType("fridge")
                if cont then
                    local items=cont:getItems()
                    for j=0,items:size()-1 do if items:get(j):getID()==scene.food then food=items:get(j) end end
                end
            end
        end
        if not food then return false end
        food:updateAge()
        rec(math.abs(food:getAge()-scene.age)<0.005,"C12 replayed food age visible on this client",food:getAge())
    else
        rec(not relayScene({rx=scene.ox,ry=scene.oy,rz=-2})
            and not relayScene({rx=scene.ox,ry=scene.oy,rz=9}),"C19 no orphan relay after reconnect")
    end
    rec(getLuaDebuggerErrorCount()==C.errors,"no new client Lua errors",getLuaDebuggerErrorCount()-C.errors)
    report(C.command);C.finished=true;return true
end
H.client.result=result
return H
