-- Live Wire with the Computer Mod and its Laptop addon (pz-autotest, single player):
-- detection, loot of the software disk, desktop app hook, install on a computer.
local H = {}
local lines, okAll = {}, true

local function rec(ok, name, detail)
    if not ok then okAll = false end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" - " .. tostring(detail)) or "")
end

local function check(name, fn)
    local ok, res, detail = pcall(fn)
    if not ok then rec(false, name, "error: " .. tostring(res)) return end
    rec(res == true, name, detail)
end

function H.start(ctx)
    local p = getPlayer()
    check("Computer Mod detected", function()
        return LiveWire.Compat.computerMod() == true and ComputerModComputerTypes ~= nil
    end)
    check("desktop app hook installed", function()
        return LiveWire.ComputerMod.patched == true
    end)
    check("software disk in the computer loot lists", function()
        local items = ProceduralDistributions.list.ElectronicStoreComputers.items
        for i = 1, #items do
            if items[i] == "LiveWire.MonitorDisk" then return true end
        end
        return false
    end)
    check("software installed on a Computer Mod desktop computer, app listed", function()
        -- A vanilla desktop computer placed next to the player.
        local sq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), math.floor(p:getZ()))
        local obj = IsoObject.new(getCell(), sq, "appliances_com_01_72")
        sq:AddSpecialObject(obj)
        if not LiveWire.ComputerMod.isComputer(obj) then return false, "not a Computer Mod computer" end
        p:getInventory():AddItem("LiveWire.MonitorDisk")
        local before = LiveWire.ComputerMod.isInstalled(obj)
        LiveWire.ComputerMod.install(obj)
        local after = LiveWire.ComputerMod.isInstalled(obj)
        local fake = { computer = obj }
        local items = ComputerScreenUI.getDesktopAppItems(fake)
        local listed = false
        for i = 1, #items do
            if items[i].app == "livewire" then listed = true end
        end
        return (not before) and after and listed, "before=" .. tostring(before) .. " after=" .. tostring(after)
            .. " listed=" .. tostring(listed)
    end)
    check("no Lua error recorded", function()
        local n = getLuaDebuggerErrorCount and getLuaDebuggerErrorCount() or 0
        return n == 0, "errors=" .. tostring(n)
    end)
    return true
end

function H.result(ctx)
    local pass, total = 0, 0
    for i = 1, #lines do
        local head = lines[i]:sub(1, 4)
        if head == "PASS" then pass = pass + 1 end
        if head == "PASS" or head == "FAIL" then total = total + 1 end
    end
    return { ok = okAll, summary = tostring(pass) .. "/" .. tostring(total) .. " PASS", lines = lines }
end

return H
