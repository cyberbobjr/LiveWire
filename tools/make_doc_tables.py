"""Markdown tables for the README and the wiki: recipes (with icons) and loot.

    python tools/make_doc_tables.py   ->  docs/wiki/_tables_en.md, docs/wiki/_tables_fr.md

Recipes come from tools/make_doc_images.RECIPES (same data as LiveWire_recipes.txt); item names from the
game and mod translations. Loot weights mirror media/lua/server/Items/LiveWire_Distributions.lua; the chance
per container is 1 - (1 - W/100)^rolls, times 0.6 for placeable furniture (vanilla "Other" modifier).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_doc_images as M  # noqa: E402

RAW = "https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/icons/"
ROLLS = {"GarageTools": 4, "CrateTools": 4, "GarageMetalwork": 4, "MechanicShelfElectric": 4, "ElectricianTools": 3,
         "MetalShopTools": 4, "WireFactoryElectric": 4, "ToolStoreMisc": 4, "ToolStoreTools": 4,
         "CarSupplyBatteries": 4, "GarageMechanics": 4}
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
# Same as LiveWire_Distributions.lua (EQUIPMENT).
EQUIPMENT = [
    ("VoltageTester", "LiveWire.VoltageTester", False,
     {"ElectricianTools": 3, "ToolStoreTools": 1, "GarageTools": 1, "CrateTools": 1, "WireFactoryElectric": 1}),
    ("DeepCycleBattery", "LiveWire.DeepCycleBattery", False,
     {"MechanicShelfElectric": 1, "CarSupplyBatteries": 2, "GarageMechanics": 0.3}),
    ("Inverter", "Base.Mov_LiveWire_Inverter", True,
     {"ElectricianTools": 0.5, "WireFactoryElectric": 0.5, "ToolStoreMisc": 0.2, "GarageTools": 0.1}),
    ("Breaker", "Base.Mov_LiveWire_Breaker", True,
     {"ElectricianTools": 1, "WireFactoryElectric": 1, "ToolStoreMisc": 0.5, "GarageTools": 0.3, "CrateTools": 0.3}),
    ("PowerBank", "Base.Mov_LiveWire_PowerBank", True,
     {"ElectricianTools": 0.5, "MechanicShelfElectric": 0.5, "ToolStoreMisc": 0.3, "GarageTools": 0.2}),
    ("BatteryAlarm", "Base.Mov_LiveWire_BatteryAlarm", True,
     {"ElectricianTools": 1, "WireFactoryElectric": 1, "ToolStoreMisc": 0.5}),
    ("WindTurbine", "Base.Mov_LiveWire_WindTurbine", True, {"ToolStoreMisc": 0.1, "WireFactoryElectric": 0.1}),
]
T = {
    "EN": {"recipe": "Recipe", "in": "Ingredients", "skill": "Skill", "out": "Result", "tools": "Tools (kept)",
           "none": "none", "loot_title": "Ready-made Live Wire equipment",
           "loot_intro": "Found already built, in addition to the crafting recipes (sandbox loot settings apply).",
           "item": "Equipment", "list": "Vanilla list", "where": "Where", "w": "Weight", "r": "Rolls",
           "c": "≈ chance per container", "furn": "furniture: × 0.6 included", "dec": "."},
    "FR": {"recipe": "Recette", "in": "Ingrédients", "skill": "Compétence", "out": "Résultat",
           "tools": "Outils (conservés)", "none": "aucune", "loot_title": "Équipements Live Wire tout faits",
           "loot_intro": "Trouvés déjà fabriqués, en plus des recettes (les réglages de butin sandbox s'appliquent).",
           "item": "Équipement", "list": "Liste vanilla", "where": "Où", "w": "Poids", "r": "Tirages",
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
            r = ROLLS[name]
            c = (1 - (1 - w / 100.0) ** r) * (0.6 if furniture else 1.0) * 100
            label = "%s **%s**%s" % (img(key), item(key), " (%s)" % t["furn"] if furniture else "") if first else ""
            out.append("| %s | `%s` | %s | %s | %d | %s %% |" % (label, name, WHERE[lang][name],
                                                               num(w, lang, 1 if w < 1 else 0), r, num(c, lang)))
            first = False
    return "\n".join(out)


def main():
    for lang in ("EN", "FR"):
        p = os.path.join(M.ROOT, "docs", "wiki", "_tables_%s.md" % lang.lower())
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write("<!-- generated by tools/make_doc_tables.py -->\n\n## RECIPES\n\n" + recipes_md(lang) +
                    "\n\n## LOOT: " + T[lang]["loot_title"] + "\n\n" + T[lang]["loot_intro"] + "\n\n" + loot_md(lang) + "\n")
        print("wrote", p)


if __name__ == "__main__":
    main()
