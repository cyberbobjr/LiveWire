"""Markdown tables for the README and the wiki: recipes (with icons) and loot.

    python tools/make_doc_tables.py   ->  docs/wiki/en/_tables.md, docs/wiki/fr/_tables.md

Recipes are read from the recipe scripts of both mods (make_doc_images.parse_recipes). Loot weights are read from
the distribution Lua files of both mods (LiveWire_Distributions.lua, LWX_Distributions.lua); the rolls of each
vanilla list come from the game's ProceduralDistributions.lua / VehicleDistributions.lua (PZ_SERVER_LUA).
The chance per selected list is 1 - (1 - W * modifier/100)^rolls. The game takes the modifier from the item's loot
category (ItemPickerJava.getLootType: DisplayCategory, tags, item type). LiveWire items fall in "Other", except the
ones whose DisplayCategory maps to another category (read from the item scripts and named in the table); every
default loot setting is 0.6 at normal rarity, so the tables use 0.6 for every item (an approximation for other
sandbox settings).
"""
import os
import re
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_doc_images as M  # noqa: E402

RAW = "https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/"
GAME_SERVER = os.environ.get("PZ_SERVER_LUA", r"D:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\server")
BASE_LOOT = os.path.join(M.BASE_MOD, "lua", "server", "Items", "LiveWire_Distributions.lua")
EXT_LOOT = os.path.join(M.EXT_MOD, "lua", "server", "Items", "LWX_Distributions.lua")
# The Lua scripts apply EquipmentLootMultiplier (default 5) to every weight, except the management disk (x1).
LOOT_MULTIPLIER = 5
# Loot modifier of every category at the default (normal) loot rarity: Other and Mechanics are both 0.6.
MODIFIER = 0.6
# DisplayCategory -> loot category of ItemPickerJava.getLootType (only its DisplayCategory branches; an item that
# matches none of them, like Electronics or Furniture, is "Other"). Values are the vanilla sandbox option keys.
LOOT_CATEGORY = {
    "VehicleMaintenance": "MechanicsLootNew", "VehicleMaintenanceWeapon": "MechanicsLootNew",
    "Material": "MaterialLootNew", "MaterialWeapon": "MaterialLootNew",
    "Gardening": "FarmingLootNew", "GardeningWeapon": "FarmingLootNew",
    "Tool": "ToolLootNew", "ToolWeapon": "ToolLootNew",
    "Cooking": "CookwareLootNew", "CookingWeapon": "CookwareLootNew",
    "FirstAid": "MedicalLootNew", "FirstAidWeapon": "MedicalLootNew",
    "Fishing": "SurvivalGearsLootNew", "FishingWeapon": "SurvivalGearsLootNew", "Trapping": "SurvivalGearsLootNew",
    "Camping": "SurvivalGearsLootNew", "FireSource": "SurvivalGearsLootNew",
}
ITEM_SCRIPTS = [os.path.join(mod, "scripts", name) for mod, name in (
    (M.BASE_MOD, "LiveWire_items.txt"), (M.BASE_MOD, "LiveWire_moveables.txt"),
    (M.EXT_MOD, "LiveWireExtended_items.txt"), (M.EXT_MOD, "LiveWireExtended_moveables.txt"))]
WHERE = {
    "EN": {"ElectricianTools": "Electrician's tools", "ToolStoreTools": "Hardware store, tools",
           "ToolStoreMisc": "Hardware store, miscellaneous", "GarageTools": "Garage tool storage",
           "CrateTools": "Tool crates", "WireFactoryElectric": "Wire factory, electrical",
           "MechanicShelfElectric": "Mechanic shop, electrical shelf", "CarSupplyBatteries": "Car parts store, batteries",
           "GarageMechanics": "Garage, mechanic storage", "CrateElectronics": "Electronics crates",
           "ElectronicStoreMisc": "Electronics store, miscellaneous", "CrateMetalwork": "Metalwork crates",
           "ToolStoreMetalwork": "Hardware store, metalwork", "MechanicShelfTools": "Mechanic shop, tools",
           "CrateMechanics": "Mechanic supply crates", "CampingStoreGear": "Camping store, gear",
           "ElectronicStoreAppliances": "Electronics store, appliances", "GarageMetalwork": "Garage metalwork storage",
           "MetalShopTools": "Metal shop tools", "WireFactoryTools": "Wire factory, tools",
           "CrateFarming": "Farming supply crates", "ToolStoreFarming": "Hardware/outdoor store, farming",
           "CrateCarpentry": "Carpentry crates", "ToolStoreCarpentry": "Hardware store, carpentry",
           "ElectricianTruckBed": "Electrician vehicle, truck bed or trunk",
           "ElectricianGloveBox": "Electrician vehicle, glove box",
           "MetalWelderTruckBed": "Metalworker vehicle, truck bed or trunk",
           "ElectronicStoreComputers": "Electronics store, computers", "CrateComputer": "Computer crates",
           "BookstoreComputer": "Bookstore, computers", "UniversityDesk_Computer": "University desk, computers",
           "UniversityDesk_Electrical": "University desk, electrical", "OfficeDesk": "Office desk"},
    "FR": {"ElectricianTools": "Outils d'électricien", "ToolStoreTools": "Quincaillerie, outils",
           "ToolStoreMisc": "Quincaillerie, divers", "GarageTools": "Rangement d'outils de garage",
           "CrateTools": "Caisses d'outils", "WireFactoryElectric": "Usine de câbles, rayon électrique",
           "MechanicShelfElectric": "Garage automobile, étagère électrique",
           "CarSupplyBatteries": "Magasin de pièces auto, batteries", "GarageMechanics": "Garage, rangement mécanique",
           "CrateElectronics": "Caisses d'électronique", "ElectronicStoreMisc": "Magasin d'électronique, divers",
           "CrateMetalwork": "Caisses de métallerie", "ToolStoreMetalwork": "Quincaillerie, métallerie",
           "MechanicShelfTools": "Garage automobile, outils", "CrateMechanics": "Caisses de mécanique",
           "CampingStoreGear": "Magasin de camping, matériel",
           "ElectronicStoreAppliances": "Magasin d'électronique, appareils", "GarageMetalwork": "Rangement de métallerie de garage",
           "MetalShopTools": "Outils de métallerie", "WireFactoryTools": "Usine de câbles, outils",
           "CrateFarming": "Caisses de matériel agricole", "ToolStoreFarming": "Quincaillerie ou magasin extérieur, agriculture",
           "CrateCarpentry": "Caisses de menuiserie", "ToolStoreCarpentry": "Quincaillerie, menuiserie",
           "ElectricianTruckBed": "Véhicule d'électricien, plateau ou coffre",
           "ElectricianGloveBox": "Véhicule d'électricien, boîte à gants",
           "MetalWelderTruckBed": "Véhicule de métallier, plateau ou coffre",
           "ElectronicStoreComputers": "Magasin d'électronique, informatique", "CrateComputer": "Caisses d'informatique",
           "BookstoreComputer": "Librairie, informatique", "UniversityDesk_Computer": "Bureau universitaire, informatique",
           "UniversityDesk_Electrical": "Bureau universitaire, électricité", "OfficeDesk": "Bureau d'entreprise"},
}
T = {
    "EN": {"recipe": "Recipe", "in": "Ingredients", "skill": "Skill", "out": "Result", "tools": "Tools (kept)",
           "none": "none", "loot_title": "Ready-made LiveWire equipment",
           "loot_intro": "Weights at the default EquipmentLootMultiplier = 5 (range 1–20). Estimates assume this loot list is selected, the game's loot modifier at normal rarity (0.6), no zombie-density or time modifiers and enough container space; they are not a guaranteed discovery rate.",
           "ext_title": "LiveWire Extended equipment", "disk_title": "Management software disk",
           "item": "Equipment", "list": "Vanilla list", "where": "Where", "w": "Weight (×5)", "w1": "Weight",
           "r": "Rolls", "c": "≈ chance per container", "cat": "loot setting: %s",
           "disk": "needs the Computer Mod", "dec": "."},
    "FR": {"recipe": "Recette", "in": "Ingrédients", "skill": "Compétence", "out": "Résultat",
           "tools": "Outils (conservés)", "none": "aucune", "loot_title": "Équipements LiveWire tout faits",
           "loot_intro": "Poids avec EquipmentLootMultiplier = 5 par défaut (plage 1–20). Estimations si cette liste est sélectionnée, avec le modificateur de butin du jeu à rareté normale (0,6), sans effet de densité de zombies ni du temps et avec assez de place ; ce ne sont pas des taux de découverte garantis.",
           "ext_title": "Équipements LiveWire Extended", "disk_title": "Disque du logiciel de gestion",
           "item": "Équipement", "list": "Liste vanilla", "where": "Où", "w": "Poids (×5)", "w1": "Poids",
           "r": "Tirages", "c": "≈ chance par conteneur", "cat": "réglage de butin : %s",
           "disk": "nécessite le Computer Mod", "dec": ","},
}


def img(key, size=24):
    return '<img src="%s%s.png" width="%d" height="%d">' % (RAW, key, size, size)


def num(x, lang, digits=1):
    return ("%.*f" % (digits, x)).replace(".", T[lang]["dec"])


# --- Recipes ------------------------------------------------------------------------------------

def recipes_md(lang, recs):
    t = T[lang]
    item, rnames, skill = M.names(lang)
    out = ["| %s | %s | %s | %s | %s |" % (t["recipe"], t["in"], t["tools"], t["skill"], t["out"]),
           "|---|---|---|---|---|"]
    for r in recs:
        if r["name"] not in rnames:
            raise KeyError("no translation for recipe %s (%s)" % (r["name"], lang))
        ing = "<br>".join("%d × %s %s" % (q, img(k), item(k)) for q, k in r["ins"])
        tl = " ".join(img(k) for k in r["tools"])
        sk = t["none"] if r["level"] is None else "%s %d" % (skill, r["level"])
        res = "<br>".join("%s%s **%s**" % ("%d × " % q if len(r["outs"]) > 1 else "", img(k, 32), item(k))
                          for q, k in r["outs"])
        out.append("| %s | %s | %s | %s | %s |" % (rnames[r["name"]], ing, tl, sk, res))
    return "\n".join(out)


# --- Loot, read from the Lua distribution scripts -----------------------------------------------

def read_lua(path):
    with open(path, encoding="utf-8-sig") as f:
        return re.sub(r"--[^\n]*", "", f.read())


def lua_block(src, name):
    m = re.search(r"\blocal\s+%s\s*=\s*\{" % name, src)
    if not m:
        raise ValueError("local %s table not found" % name)
    depth, i = 1, m.end()
    while depth:
        c = src[i]
        depth += (c == "{") - (c == "}")
        i += 1
    return src[m.end():i - 1]


def flat(body):
    return {k: float(v) for k, v in re.findall(r"(\w+)\s*=\s*([\d.]+)", body)}


def keyed(body):
    return {k: flat(v) for k, v in re.findall(r'\["([\w.]+)"\]\s*=\s*\{([^{}]*)\}', body)}


def loot_categories():
    """{full type: vanilla sandbox loot option key} for the items whose DisplayCategory is not "Other"."""
    out = {}
    for path in ITEM_SCRIPTS:
        with open(path, encoding="utf-8-sig") as f:
            src = f.read()
        module = re.search(r"\bmodule\s+(\w+)", src).group(1)
        for name, body in re.findall(r"\bitem\s+(\w+)\s*\{([^{}]*)\}", src):
            m = re.search(r"DisplayCategory\s*=\s*(\w+)", body)
            if m and m.group(1) in LOOT_CATEGORY:
                out["%s.%s" % (module, name)] = LOOT_CATEGORY[m.group(1)]
    return out


def category_name(lang, key):
    """Name of the vanilla loot rarity setting, as the sandbox page shows it."""
    names = M.load_json(os.path.join(M.GAME_TR, "EN", "Sandbox.json"))
    names.update(M.load_json(os.path.join(M.GAME_TR, lang, "Sandbox.json")))
    return names.get("Sandbox_" + key, key.replace("LootNew", ""))


def load_loot():
    """(cells, items): vanilla list weights of solar cells, and per item {list: weight x1} with its multiplier and
    its group (cell, disk, base, ext)."""
    base = read_lua(BASE_LOOT)
    ext = read_lua(EXT_LOOT)
    cells = flat(lua_block(base, "CELL_LISTS"))
    items = OrderedDict()

    def put(full, lists, mult, group="base"):
        entry = items.setdefault(full, {"lists": {}, "mult": mult, "group": group})
        entry["lists"].update(lists)
    put("LiveWire.SolarCell", cells, LOOT_MULTIPLIER, "cell")
    put("Base.Mov_LiveWire_SolarPanel", flat(lua_block(base, "PANEL_LISTS")), LOOT_MULTIPLIER)
    # equipment(...) adds the disk without the multiplier
    put("LiveWire.MonitorDisk", flat(lua_block(base, "DISK_LISTS")), 1, "disk")
    for full, lists in keyed(lua_block(base, "EQUIPMENT")).items():
        put(full, lists, LOOT_MULTIPLIER)
    for full, lists in keyed(lua_block(base, "VEHICLE")).items():
        put(full, lists, LOOT_MULTIPLIER)
    pro = flat(lua_block(ext, "PRO"))
    house = flat(lua_block(ext, "HOUSE"))
    for full, rest in re.findall(r'item = "([\w.]+)"([^{}]*)', lua_block(ext, "ENTRIES")):
        w = float(re.search(r"weight = ([\d.]+)", rest).group(1))
        lists = {}
        if re.search(r"lists = PRO\b", rest):
            lists.update({k: w * f for k, f in pro.items()})
        if re.search(r"house = HOUSE\b", rest):
            lists.update({k: w * f for k, f in house.items()})
        vm = re.search(r"vehicle = ([\d.]+)", rest)
        if vm:
            lists["ElectricianTruckBed"] = float(vm.group(1))
        put(full, lists, LOOT_MULTIPLIER, "ext")
    return cells, items


def vanilla_rolls():
    """Rolls of each vanilla list used here (game files, read only)."""
    proc = read_lua(os.path.join(GAME_SERVER, "Items", "ProceduralDistributions.lua"))
    veh = read_lua(os.path.join(GAME_SERVER, "Vehicles", "VehicleDistributions.lua"))
    rolls = {}
    # "name = {" then optional "key = value," lines (isShop = true, ...) then "rolls = N,".
    field = r"\w+\s*=\s*[^,\n{}]+,\s*"
    for name, n in re.findall(r"^\s*(\w+)\s*=\s*\{\s*(?:" + field + r")*?rolls\s*=\s*(\d+)", proc, re.M):
        rolls.setdefault(name, int(n))
    for name, n in re.findall(r"VehicleDistributions\.(\w+)\s*=\s*\{\s*(?:" + field + r")*?rolls\s*=\s*(\d+)", veh):
        rolls.setdefault(name, int(n))
    return rolls


def chance(weight, rolls):
    return (1 - (1 - weight * MODIFIER / 100.0) ** rolls) * 100


def cells_md(lang, cells, rolls):
    t = T[lang]
    out = ["| %s | %s | %s | %s | %s |" % (t["list"], t["where"], t["w"], t["r"], t["c"]), "|---|---|---|---|---|"]
    # cells: every list of the solar cell, shops and crates (CELL_LISTS) and vehicles (VEHICLE)
    for name, base in cells.items():
        weight = base * LOOT_MULTIPLIER
        out.append("| `%s` | %s | %s | %d | %s %% |" % (name, WHERE[lang][name], num(weight, lang, 0),
                                                       rolls[name], num(chance(weight, rolls[name]), lang)))
    return "\n".join(out)


def loot_md(lang, items, rolls, group, cats):
    t = T[lang]
    item, _, _ = M.names(lang)
    w = t["w1"] if group == "disk" else t["w"]
    out = ["| %s | %s | %s | %s | %s | %s |" % (t["item"], t["list"], t["where"], w, t["r"], t["c"]),
           "|---|---|---|---|---|---|"]
    for full, entry in items.items():
        if entry["group"] != group:
            continue
        key = M.short(full)
        M.FULL_NAMES.setdefault(key, full)
        note = ""
        if full in cats:
            note = " (%s)" % (t["cat"] % category_name(lang, cats[full]))
        if full == "LiveWire.MonitorDisk":
            note = " (%s)" % t["disk"]
        first = True
        for name, w in sorted(entry["lists"].items(), key=lambda kv: -kv[1]):
            weight = w * entry["mult"]
            r = rolls[name]
            label = ("%s **%s**%s" % (img(key), item(key), note)) if first else ""
            out.append("| %s | `%s` | %s | %s | %d | %s %% |" % (label, name, WHERE[lang][name],
                                                               num(weight, lang, 0 if weight % 1 == 0 else 1), r,
                                                               num(chance(weight, r), lang)))
            first = False
    return "\n".join(out)


def main():
    _, items = load_loot()
    rolls = vanilla_rolls()
    cats = loot_categories()
    for lang in ("EN", "FR"):
        p = os.path.join(M.ROOT, "docs", "wiki", lang.lower(), "_tables.md")
        crafts = [r for r in M.BASE_RECIPE_LIST if r["kind"] == "craft"]
        dismantles = [r for r in M.BASE_RECIPE_LIST if r["kind"] == "dismantle"]
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write("<!-- generated by tools/make_doc_tables.py -->\n\n## RECIPES\n\n" + recipes_md(lang, crafts) +
                    "\n\n## DISMANTLING\n\n" + recipes_md(lang, dismantles) +
                    "\n\n## RECIPES EXTENDED\n\n" + recipes_md(lang, M.EXT_RECIPE_LIST) +
                    "\n\n## CELLS (x5)\n\n" + cells_md(lang, items["LiveWire.SolarCell"]["lists"], rolls) +
                    "\n\n## LOOT: " + T[lang]["loot_title"] + "\n\n" + T[lang]["loot_intro"] + "\n\n" +
                    loot_md(lang, items, rolls, "base", cats) +
                    "\n\n## LOOT EXTENDED: " + T[lang]["ext_title"] + "\n\n" +
                    loot_md(lang, items, rolls, "ext", cats) +
                    "\n\n## DISK: " + T[lang]["disk_title"] + "\n\n" +
                    loot_md(lang, items, rolls, "disk", cats) + "\n")
        print("wrote", p)


if __name__ == "__main__":
    main()
