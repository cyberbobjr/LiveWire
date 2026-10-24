-- C25 three-process-lifecycle test: create -> reload/remove -> restart clean.
local H={server={},client={}}
local S,C={},{}
local lines,okAll={},true
local function rec(ok,name,detail)
    if not ok then okAll=false end
    lines[#lines+1]=(ok and "PASS " or "FAIL ")..name.." - "..tostring(detail or "")
end
local function check(name,fn)
    local ok,value,detail=pcall(fn)
    rec(ok and value==true,name,ok and detail or value)
end
local function result()
    local pass=0
    for i=1,#lines do if lines[i]:sub(1,4)=="PASS" then pass=pass+1 end end
    return {ok=okAll,summary=pass.."/"..#lines.." PASS",lines=lines}
end
local function report(label)
    if isClient() then sendClientCommand(getPlayer(),"LWC25","seen",{label=label})
    else S.seen[label]=S.seen[label] or {};S.seen[label].solo=true end
end
local function receive(command,args)
    C.command,C.args,C.at=command,args,getTimestampMs()
end
local function notify(command,args)
    if isServer() then
        for _,p in ipairs(S.ctx.players()) do sendServerCommand(p,"LWC25",command,args or S.scene) end
    else receive(command,args or S.scene) end
end
local function allSeen(label)
    local n=0
    for _ in pairs(S.seen[label] or {}) do n=n+1 end
    return n>=S.observers
end
local function place(sq,name)
    local props=ISMoveableSpriteProps.new(getSprite(name))
    return props:placeMoveableInternal(S.player,sq,props:instanceItem(name),name)
end
local function findRelay(scene)
    return LiveWire.Pump.findRelay(scene.x,scene.y,scene.z)
end
local function debugCommand(action)
    LiveWire.Commands.handle(S.player,LiveWire.Protocol.C_DEBUG,{action=action})
end
local function authorityStart(ctx)
    S.ctx,S.phase,S.seen=ctx,ctx.params.phase,{}
    S.observers=isServer() and #ctx.players() or 1
    S.player=isServer() and ctx.players()[1] or getPlayer()
    S.errors=getLuaDebuggerErrorCount()
    S.started=getTimestampMs()
    rec(tostring(getCore():getVersionNumber())=="42.21","runtime 42.21")
    local R=LiveWire.Registry
    local scene=ModData.getOrCreate("LiveWireC25Test")
    S.scene=scene
    check("C11 stable anchor state does not trigger publication",function()
        local inv={id="C25_probe",x=0,y=0,z=0}
        R.anchors[inv.id]={x=0,y=0,z=0,on=false}
        local changed=false
        for _=1,100 do if R.setAnchor(inv,false) then changed=true end end
        R.anchors[inv.id]=nil
        return not changed,"100 unchanged calls"
    end)
    if S.phase=="create" then
        S.player:setPerkLevelDebug(Perks.Electricity,10)
        local origin=S.player:getCurrentSquare()
        scene.ox,scene.oy,scene.oz=origin:getX(),origin:getY(),origin:getZ()
        local ground
        for d=3,40 do
            for dx=-d,d do
                local sq=getCell():getGridSquare(scene.ox+dx,scene.oy+d,scene.oz)
                if not ground and sq and sq:isOutside() and sq:isSolidFloor()
                    and not getCell():getGridSquare(sq:getX(),sq:getY(),sq:getZ()+1) then ground=sq end
            end
        end
        if not ground then return false,"no loaded ground with a fresh square above" end
        scene.x,scene.y,scene.z=ground:getX(),ground:getY(),ground:getZ()+1
        local obj=place(origin,"batman_livewire_01_72")
        if not obj then return false,"pump placement failed" end
        scene.pump=LiveWire.Marks.get(obj).id
        local dev=R.device(scene.pump)
        -- The protocol prototype isolates resource/persistence from discovery.
        -- The normal discovery and flow are covered by the other SP/MP campaigns.
        LiveWire.Pump.placeRelay(dev,scene.x,scene.y,scene.z)
        local relay=findRelay(scene)
        rec(relay~=nil,"relay created on a genuinely new z+1 square")
        if not relay then return false,"relay creation failed" end
        relay:getFluidContainer():addFluid(Fluid.Water,7.25)
        relay:sync()
        R.data.pumpsDisabled=true
    end
    check("relay persistence and absence of duplicate objects",function()
        local relay=findRelay(scene)
        if S.phase=="clean" then return relay==nil and R.data.pumpsDisabled==true end
        if not relay then return false,"relay missing after load" end
        local fc=relay:getFluidContainer()
        local sq=relay:getSquare()
        local count=0
        for i=0,sq:getObjects():size()-1 do
            if LiveWire.Install.isRelay(sq:getObjects():get(i)) then count=count+1 end
        end
        return count==1 and math.abs(fc:getAmount()-7.25)<0.001 and fc:getCapacity()==25
            and relay:getModData()[LiveWire.Defs.RELAY_KEY].pump==scene.pump
            and R.device(scene.pump).relays[LiveWire.posKey(scene.x,scene.y,scene.z)]~=nil,
            "count="..count..", litres="..fc:getAmount()
    end)
    S.stage="initial"
    notify("scene",scene)
    return true
end
local function authorityDone()
    if S.finished then return true end
    if getTimestampMs()-S.started>120000 then
        rec(false,"authority timeout",S.stage.." player="..S.player:getX()..","..S.player:getY())
        return true
    end
    local scene=S.scene
    if S.stage=="initial" and allSeen("initial") then
        if S.phase~="reload" then S.stage="finish"
        else
            check("C01 removes loaded relay through the real debug command",function()
                debugCommand("removeRelays")
                return findRelay(scene)==nil and LiveWire.Pump.disabled()
            end)
            notify("loadedRemoved");S.stage="loadedRemoved"
        end
    elseif S.stage=="loadedRemoved" and allSeen("loadedRemoved") then
        -- A second relay is deliberately left on disk for the unloaded cleanup.
        local dev=LiveWire.Registry.device(scene.pump)
        LiveWire.Pump.placeRelay(dev,scene.x,scene.y,scene.z)
        local relay=findRelay(scene)
        relay:getFluidContainer():addFluid(Fluid.Water,7.25);relay:sync()
        notify("away");S.stage="unload"
    elseif S.stage=="unload" then
        if getCell():getGridSquare(scene.x,scene.y,scene.z)~=nil then return false end
        rec(true,"relay chunk genuinely unloaded on authority")
        check("C01 clears entries while relay is in an unloaded chunk",function()
            debugCommand("removeRelays")
            local dev=LiveWire.Registry.device(scene.pump)
            return dev.relays[LiveWire.posKey(scene.x,scene.y,scene.z)]==nil
                and LiveWire.Pump.disabled()
        end)
        notify("return");S.stage="return"
    elseif S.stage=="return" then
        local ground=getCell():getGridSquare(scene.x,scene.y,scene.z-1)
        if not ground then return false end
        check("C01 removes disk orphan on native LoadChunk",function() return findRelay(scene)==nil end)
        local dev=LiveWire.Registry.device(scene.pump)
        LiveWire.Pump.maintain(dev);LiveWire.Pump.step(dev)
        notify("returnedRemoved");S.stage="returnedRemoved"
    elseif S.stage=="returnedRemoved" and allSeen("returnedRemoved") then
        rec(findRelay(scene)==nil,"disabled pump does not recreate removed relay")
        S.stage="finish"
    end
    if S.stage=="finish" then
        rec(getLuaDebuggerErrorCount()==S.errors,"no new authority Lua error",
            getLuaDebuggerErrorCount()-S.errors)
        notify("finish");S.finished=true;return true
    end
    return false
end
local function clientDone()
    if C.finished then return true end
    if not C.command then return false end
    local command,scene=C.command,C.args
    if command=="scene" then
        local sq=getCell():getGridSquare(scene.x,scene.y,scene.z)
        local relay
        if sq then
            for i=0,sq:getObjects():size()-1 do
                local o=sq:getObjects():get(i)
                if LiveWire.Install.isRelay(o) then relay=o end
            end
        end
        if C.phase~="clean" and not relay then return false end
        if C.phase=="clean" then rec(relay==nil,"no relay after final process restart")
        else
            check("client receives relay, water and ownership after load/reconnect",function()
                local fc=relay:getFluidContainer()
                return fc and math.abs(fc:getAmount()-7.25)<0.001
                    and relay:getModData()[LiveWire.Defs.RELAY_KEY].pump==scene.pump
            end)
            check("client relay texture has no opaque pixel",function()
                local tex=relay:getSprite():getTextureForCurrentFrame(IsoDirections.N)
                if not tex then
                    -- The packer omits fully transparent cells. This tile has a
                    -- tiledef but no atlas texture, so IsoSprite renders nothing.
                    -- A visible pump is the control against a missing whole pack.
                    local ps=getCell():getGridSquare(scene.ox,scene.oy,scene.oz)
                    local pump=LiveWire.Marks.findOnSquare(ps,scene.pump)
                    local control=pump and pump:getSprite():getTextureForCurrentFrame(IsoDirections.N)
                    return control~=nil and relay:getSprite():getName()==LiveWire.Defs.RELAY_SPRITE,
                        "empty relay sprite; pump texture present="..tostring(control~=nil)
                end
                for x=0,tex:getWidth()-1 do
                    for y=0,tex:getHeight()-1 do
                        if tex:isMaskSet(x+tex:getOffsetX(),y+tex:getOffsetY()) then return false,"opaque pixel" end
                    end
                end
                return true,tex:getWidth().."x"..tex:getHeight()
            end)
            check("relay does not block movement or allow dismantling",function()
                return relay:isCanPassThrough() and not relay:isBlockAllTheSquare() and not relay:isDismantable()
            end)
        end
        C.scene=scene;report("initial");C.command=nil
    elseif command=="loadedRemoved" or command=="returnedRemoved" then
        scene=C.scene
        local sq=getCell():getGridSquare(scene.x,scene.y,scene.z)
        if not sq and command=="loadedRemoved" then return false end
        if sq then
            for i=0,sq:getObjects():size()-1 do
                if LiveWire.Install.isRelay(sq:getObjects():get(i)) then return false end
            end
        end
        rec(true,"client sees no relay: "..command)
        report(command);C.command=nil
    elseif command=="away" or command=="return" then
        scene=C.scene
        local x,y=scene.ox,scene.oy
        if command=="away" then x=x+300 end
        if isClient() then SendCommandToServer("/teleportto "..x..","..y..","..scene.oz)
        else
            getPlayer():setX(x+0.5);getPlayer():setY(y+0.5)
            getPlayer():setLastX(getPlayer():getX());getPlayer():setLastY(getPlayer():getY())
        end
        C.command=nil
    elseif command=="finish" then
        rec(getLuaDebuggerErrorCount()==C.errors,"no new client Lua error")
        C.finished=true;return true
    end
    return false
end
function H.server.start(ctx)
    Events.OnClientCommand.Add(function(module,command,player,args)
        if module=="LWC25" and command=="seen" then
            S.seen[args.label]=S.seen[args.label] or {}
            S.seen[args.label][player:getUsername()]=true
        end
    end)
    return authorityStart(ctx)
end
H.server.done=authorityDone
H.server.result=result
function H.client.start(ctx)
    C.phase,C.errors=ctx.params.phase,getLuaDebuggerErrorCount()
    if not isClient() then return authorityStart(ctx) end
    Events.OnServerCommand.Add(function(module,command,args)
        if module=="LWC25" then receive(command,args or {}) end
    end)
    return true
end
function H.client.done()
    local finished=clientDone()
    if not isClient() then return authorityDone() end
    return finished
end
H.client.result=result
return H
