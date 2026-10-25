-- Live Wire: local rules for native stackable power banks, no persistent cache.
LiveWire=LiveWire or {}
local Stack={MAX_BANKS=2,HEIGHT=18}
LiveWire.Stack=Stack
function Stack.isBank(obj) return LiveWire.Defs.modelOfObject(obj)=="PowerBank" end
function Stack.banks(sq)
    local out={}
    local list=sq and sq:getObjects()
    for i=0,list and list:size()-1 or -1 do
        local obj=list:get(i)
        if Stack.isBank(obj) then out[#out+1]=obj end
    end
    table.sort(out,function(a,b)
        if a:getRenderYOffset()~=b:getRenderYOffset() then return a:getRenderYOffset()<b:getRenderYOffset() end
        return a:getObjectIndex()<b:getObjectIndex()
    end)
    return out
end
function Stack.position(obj)
    local banks=Stack.banks(obj and obj:getSquare())
    for i,o in ipairs(banks) do if o==obj then return i,#banks end end
    return 1,1
end
function Stack.canPlace(sq)
    if not sq then return false,"Tooltip_LW_Invalid" end
    local banks=Stack.banks(sq)
    if #banks>=Stack.MAX_BANKS then return false,"Tooltip_LW_BankStackFull" end
    local list=sq:getObjects()
    for i=0,list:size()-1 do
        local obj=list:get(i)
        local props=obj:getProperties()
        if props and props:isTable() and not Stack.isBank(obj) then
            return false,"Tooltip_LW_BankStackBase"
        end
    end
    return true
end
-- Removing/rotating a support would move every table above it. Preserve contents,
-- device IDs and electrical links by requiring the top unit to be removed first.
function Stack.canMove(obj)
    if not Stack.isBank(obj) then return true end
    local sq=obj:getSquare()
    if not sq or obj:getObjectIndex()==-1 then return false end
    local list=sq:getObjects()
    for i=0,list:size()-1 do
        local other=list:get(i)
        local props=other:getProperties()
        if other~=obj and props and (props:isTableTop()
            or (props:isTable() and other:getObjectIndex()>obj:getObjectIndex())) then
            return false,"Tooltip_LW_BankStackSupport"
        end
    end
    return true
end
