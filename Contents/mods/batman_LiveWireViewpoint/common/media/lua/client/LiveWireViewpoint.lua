-- Live Wire - Viewpoint models: registers the model manifest of the pack with Project Viewpoint's
-- model pack API (arguments: mod id, manifest path relative to this mod). Does nothing when Viewpoint
-- is not active.
--
-- Why this registration exists beside pack.properties: Viewpoint 0.1.7 looks for packs in the new format
-- only once, at game startup, in the mods enabled from the main menu. A mod enabled only by a save or by
-- a server is never found that way, and a found pack stays off until the player switches it on. A pack
-- registered here is loaded whenever the mod is, and Viewpoint draws it without any step from the player.
--
-- Viewpoint also finds this call by reading the mods' Lua files: it only recognises a direct register
-- call whose two arguments are string literals. Keep the call below written that way (no pcall wrapper,
-- no variable in the arguments).

local registered = false

local function register()
    if registered or not Viewpoint or not Viewpoint.ModelPacks then return end
    registered = Viewpoint.ModelPacks.register("batman_LiveWireViewpoint", "media/viewpoint/resourcepacks/batman-livewire/models.properties")
        and true or false
end

Events.OnGameBoot.Add(register)
Events.OnGameStart.Add(register)
register()
