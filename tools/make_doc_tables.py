"""Markdown tables for the README and the wiki: recipes (with icons) and loot.

    python tools/make_doc_tables.py   ->  docs/wiki/en/_tables.md, docs/wiki/fr/_tables.md

Recipes come from tools/make_doc_images.RECIPES (same data as LiveWire_recipes.txt); item names from the
game and mod translations. Loot weights mirror media/lua/server/Items/LiveWire_Distributions.lua; the chance
per selected list is 1 - (1 - W * modifier/100)^rolls, using modifier 0.6 in the examples.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_doc_images as M  # noqa: E402

RAW = "https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/images/icons/"
ROLLS = {"GarageTools": 4, "CrateTools": 4, "GarageMetalwork": 4, "MechanicShelfElectric": 4, "ElectricianTools": 3,
         "MetalShopTools": 4, "WireFactoryElectric": 4, "ToolStoreMisc": 4, "ToolStoreTools": 4,
         "CarSupplyBatteries": 4, "GarageMechanics": 4,
         "CrateElectronics": 4, "ElectronicStoreMisc": 4, "CrateMetalwork": 4,
         "ToolStoreMetalwork": 4, "MechanicShelfTools": 4, "CrateMechanics": 4,
         "CampingStoreGear": 4, "ElectronicStoreAppliances": 1}
ROLLS.update(WireFactoryTools=4, CrateFarming=4, ToolStoreFarming=4, CrateCarpentry=4, ToolStoreCarpentry=4)
WHERE = {
    "EN": {"ElectricianTools": "Electrician's tools", "ToolStoreTools": "Hardware store, tools",
           "ToolStoreMisc": "Hardware store, miscellaneous", "GarageTools": "Garage tool storage",
           "CrateTools": "Tool crates", "WireFactoryElectric": "Wire factory, electrical",
           "MechanicShelfElectric": "Mechanic shop, electrical shelf", "CarSupplyBatteries": "Car parts store, batteries",
           "GarageMechanics": "Garage, mechanic storage"},
    "FR": {"ElectricianTools": "Outils d'électricien", "ToolStoreTools": "Quincaillerie, outils",
           "ToolStoreMisc": "Quincaillerie, divers", "GarageTools": "Rangement d'outils de garage",
           "CrateTools": "Caisses d'outils", "WireFactoryElectric": "Usine de câbles, rayon électrique",
           "MechanicShelfElectric": "Garage automobile, étagère électrique",
           "CarSupplyBatteries": "Magasin de pièces auto, batteries", "GarageMechanics": "Garage, rangement mécanique"},
}
WHERE['EN'].update(CrateElectronics='Electronics crates', ElectronicStoreMisc='Electronics store, miscellaneous',
    CrateMetalwork='Metalwork crates', ToolStoreMetalwork='Hardware store, metalwork',
    MechanicShelfTools='Mechanic shop, tools', CrateMechanics='Mechanic supply crates',
    CampingStoreGear='Camping store, gear', ElectronicStoreAppliances='Electronics store, appliances',
    GarageMetalwork='Garage metalwork storage')
WHERE['EN']['MetalShopTools'] = 'Metal shop tools'
WHERE['FR'].update(CrateElectronics="Caisses d'électronique", ElectronicStoreMisc="Magasin d'électronique, divers",
    CrateMetalwork='Caisses de métallerie', ToolStoreMetalwork='Quincaillerie, métallerie',
    MechanicShelfTools='Garage automobile, outils', CrateMechanics='Caisses de mécanique',
    CampingStoreGear='Magasin de camping, matériel', ElectronicStoreAppliances="Magasin d'électronique, appareils",
    GarageMetalwork='Rangement de métallerie de garage')
WHERE['FR']['MetalShopTools'] = 'Outils de métallerie'
WHERE['EN'].update(WireFactoryTools='Wire factory, tools', CrateFarming='Farming supply crates',
    ToolStoreFarming='Hardware/outdoor store, farming', CrateCarpentry='Carpentry crates',
    ToolStoreCarpentry='Hardware store, carpentry')
WHERE['FR'].update(WireFactoryTools='Usine de câbles, outils', CrateFarming='Caisses de matériel agricole',
    ToolStoreFarming='Quincaillerie ou magasin extérieur, agriculture', CrateCarpentry='Caisses de menuiserie',
    ToolStoreCarpentry='Quincaillerie, menuiserie')
# Base weights from LiveWire_Distributions.lua; displayed at the default x5.
LOOT_MULTIPLIER = 5
CELL_LISTS = {'GarageTools': 2, 'CrateTools': 1, 'GarageMetalwork': 1, 'MechanicShelfElectric': 2,
              'ElectricianTools': 3, 'MetalShopTools': 1, 'WireFactoryElectric': 2, 'ToolStoreMisc': 2,
              'CrateElectronics': 2, 'ElectronicStoreMisc': 2, 'ToolStoreMetalwork': 1, 'CrateMetalwork': 1}
EQUIPMENT = [
    ("SolarPanel", "Base.Mov_LiveWire_SolarPanel", True,
     {"GarageTools": 0.3, "CrateTools": 0.3, "GarageMetalwork": 0.2, "ToolStoreMisc": 0.5, "ToolStoreTools": 0.3,
      "CrateElectronics": 0.5, "ElectronicStoreMisc": 0.5, "CrateMetalwork": 0.3, "ToolStoreMetalwork": 0.3}),
    ("VoltageTester", "LiveWire.VoltageTester", False,
     {"ElectricianTools": 3, "ToolStoreTools": 1, "GarageTools": 1, "CrateTools": 1, "WireFactoryElectric": 1,
      "ElectronicStoreMisc": 1, "CrateElectronics": 1, "MechanicShelfElectric": 1, "MechanicShelfTools": 1}),
    ("DeepCycleBattery", "LiveWire.DeepCycleBattery", False,
     {"MechanicShelfElectric": 1, "CarSupplyBatteries": 2, "GarageMechanics": 0.3,
      "CrateMechanics": 0.7, "CrateElectronics": 0.5, "ElectronicStoreMisc": 0.5, "CampingStoreGear": 0.3}),
    ("Inverter", "Base.Mov_LiveWire_Inverter", True,
     {"ElectricianTools": 0.5, "WireFactoryElectric": 0.5, "ToolStoreMisc": 0.2, "GarageTools": 0.1,
      "CrateElectronics": 0.5, "ElectronicStoreMisc": 0.5, "ElectronicStoreAppliances": 0.3,
      "MechanicShelfElectric": 0.3, "CrateTools": 0.2}),
    ("Breaker", "Base.Mov_LiveWire_Breaker", True,
     {"ElectricianTools": 1, "WireFactoryElectric": 1, "ToolStoreMisc": 0.5, "GarageTools": 0.3, "CrateTools": 0.3,
      "CrateElectronics": 0.7, "ElectronicStoreMisc": 0.5, "ToolStoreTools": 0.5, "CrateMetalwork": 0.3}),
    ("PowerBank", "Base.Mov_LiveWire_PowerBank", True,
     {"ElectricianTools": 0.5, "MechanicShelfElectric": 0.5, "ToolStoreMisc": 0.3, "GarageTools": 0.2,
      "CrateElectronics": 0.5, "ElectronicStoreMisc": 0.4, "CrateMechanics": 0.3,
      "GarageMechanics": 0.2, "CrateTools": 0.2}),
    ("BatteryAlarm", "Base.Mov_LiveWire_BatteryAlarm", True,
     {"ElectricianTools": 1, "WireFactoryElectric": 1, "ToolStoreMisc": 0.5,
      "CrateElectronics": 0.7, "ElectronicStoreMisc": 0.5, "CrateTools": 0.3, "GarageTools": 0.3}),
    ("WindTurbine", "Base.Mov_LiveWire_WindTurbine", True,
     {"ToolStoreMisc": 0.3, "WireFactoryElectric": 0.5, "CrateElectronics": 0.3,
      "CrateMetalwork": 0.3, "ToolStoreMetalwork": 0.5, "CrateTools": 0.3,
      "WireFactoryTools": 0.5, "CrateFarming": 0.3, "ToolStoreFarming": 0.3, "MechanicShelfTools": 0.3}),
    ("WaterWheel", "Base.Mov_LiveWire_WaterWheel", True,
     {"CrateCarpentry": 0.5, "ToolStoreCarpentry": 0.5, "CrateFarming": 0.5,
      "ToolStoreFarming": 0.3, "CrateTools": 0.3, "CrateMechanics": 0.3, "CrateMetalwork": 0.3}),
    ("WindTurbineBlades", "LiveWire.WindTurbineBlades", False,
     {"CrateMetalwork": 1, "ToolStoreMetalwork": 1, "CrateTools": 0.7,
      "CrateFarming": 0.7, "ToolStoreFarming": 0.7, "WireFactoryTools": 0.7}),
    ("WindTurbineMast", "LiveWire.WindTurbineMast", False,
     {"CrateMetalwork": 1, "ToolStoreMetalwork": 1, "CrateTools": 0.7,
      "CrateMechanics": 0.7, "CrateFarming": 0.7, "ToolStoreFarming": 0.7}),
]
T = {
    "EN": {"recipe": "Recipe", "in": "Ingredients", "skill": "Skill", "out": "Result", "tools": "Tools (kept)",
           "none": "none", "loot_title": "Ready-made Live Wire equipment",
           "loot_intro": "Ready-made equipment, at the default EquipmentLootMultiplier = 5 (range 1–20). Estimates assume this loot list is selected, a vanilla loot modifier of 0.6, no zombie-density or time modifiers and enough container space; they are not a guaranteed discovery rate.",
           "item": "Equipment", "list": "Vanilla list", "where": "Where", "w": "Weight (×5)", "r": "Rolls",
           "c": "≈ chance per container", "furn": "furniture: × 0.6 included", "dec": "."},
    "FR": {"recipe": "Recette", "in": "Ingrédients", "skill": "Compétence", "out": "Résultat",
           "tools": "Outils (conservés)", "none": "aucune", "loot_title": "Équipements Live Wire tout faits",
           "loot_intro": "Équipements tout faits, avec EquipmentLootMultiplier = 5 par défaut (plage 1–20). Estimations si cette liste est sélectionnée, avec un modificateur vanilla de 0,6, sans effet de densité de zombies ni du temps et avec assez de place ; ce ne sont pas des taux de découverte garantis.",
           "item": "Équipement", "list": "Liste vanilla", "where": "Où", "w": "Poids (×5)", "r": "Tirages",
           "c": "≈ chance par conteneur", "furn": "meuble : × 0,6 inclus", "dec": ","},
}


def img(key, size=24):
    return '<img src="%s%s.png" width="%d" height="%d">' % (RAW, key, size, size)


def num(x, lang, digits=1):
    return ("%.*f" % (digits, x)).replace(".", T[lang]["dec"])


def recipes_md(lang):
    t = T[lang]
    item, rnames, skill = M.names(lang)
    out = ["| %s | %s | %s | %s |" % (t["in"], t["tools"], t["skill"], t["out"]), "|---|---|---|---|"]
    for rk, lvl, ins, tools, outs in M.RECIPES:
        ing = "<br>".join("%d × %s %s" % (q, img(k), item(k)) for q, k in ins)
        tl = " ".join(img(k) for k in tools)
        sk = t["none"] if lvl is None else "%s %d" % (skill, lvl)
        res = "<br>".join("%s%s **%s**" % ("%d × " % q if len(outs) > 1 else "", img(k, 32), item(k)) for q, k in outs)
        out.append("| %s | %s | %s | %s |" % (ing, tl, sk, res))
    return "\n".join(out)


def loot_md(lang):
    t = T[lang]
    item, _, _ = M.names(lang)
    out = ["| %s | %s | %s | %s | %s | %s |" % (t["item"], t["list"], t["where"], t["w"], t["r"], t["c"]),
           "|---|---|---|---|---|---|"]
    for key, _, furniture, lists in EQUIPMENT:
        first = True
        for name, w in sorted(lists.items(), key=lambda kv: -kv[1]):
            w *= LOOT_MULTIPLIER
            r = ROLLS[name]
            c = (1 - (1 - w * 0.6 / 100.0) ** r) * 100
            label = "%s **%s**%s" % (img(key), item(key), " (%s)" % t["furn"] if furniture else "") if first else ""
            out.append("| %s | `%s` | %s | %s | %d | %s %% |" % (label, name, WHERE[lang][name],
                                                               num(w, lang, 0 if w % 1 == 0 else 1), r, num(c, lang)))
            first = False
    return "\n".join(out)


def cells_md(lang):
    t = T[lang]
    out = ['| %s | %s | %s | %s | %s |' % (t['list'], t['where'], t['w'], t['r'], t['c']),
           '|---|---|---|---|---|']
    for name, base in CELL_LISTS.items():
        weight, rolls = base * LOOT_MULTIPLIER, ROLLS[name]
        chance = (1 - (1 - weight * 0.6 / 100.0) ** rolls) * 100
        out.append('| `%s` | %s | %s | %d | %s %% |' %
                   (name, WHERE[lang][name], num(weight, lang, 0), rolls, num(chance, lang)))
    return '\n'.join(out)


def main():
    for lang in ("EN", "FR"):
        p = os.path.join(M.ROOT, "docs", "wiki", lang.lower(), "_tables.md")
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write("<!-- generated by tools/make_doc_tables.py -->\n\n## RECIPES\n\n" + recipes_md(lang) +
                    "\n\n## CELLS (x5)\n\n" + cells_md(lang) +
                    "\n\n## LOOT: " + T[lang]["loot_title"] + "\n\n" + T[lang]["loot_intro"] + "\n\n" + loot_md(lang) + "\n")
        print("wrote", p)


if __name__ == "__main__":
    main()
