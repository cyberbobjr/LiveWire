# -*- coding: utf-8 -*-
"""Source of the Live Wire translations (EN reference, FR). Generates the JSON files.

Run: python3 -I tools/translations_src.py
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media", "lua", "shared", "Translate")

T = {}  # file -> key -> (EN, FR)

def add(f, key, en, fr):
    T.setdefault(f, {})[key] = (en, fr)

# Item names (key Module.Type, Translator.getItemNameFromFullType).
for k, en, fr in [
    ("LiveWire.VoltageTester", "Voltage Tester", "Testeur de tension"),
    ("LiveWire.SolarCell", "Solar Cell", "Cellule photovoltaïque"),
    ("LiveWire.SolarPanelKit", "Solar Panel Kit", "Panneau photovoltaïque en kit"),
    ("LiveWire.WindTurbineKit", "Wind Turbine Kit", "Éolienne en kit"),
    ("LiveWire.InverterKit", "Inverter Kit", "Onduleur en kit"),
    ("LiveWire.HeavyInverterKit", "Heavy Inverter Kit", "Onduleur renforcé en kit"),
    ("LiveWire.PowerBankKit", "Power Bank Kit", "Powerbank en kit"),
    ("LiveWire.BreakerKit", "Circuit Breaker Kit", "Disjoncteur en kit"),
    ("LiveWire.DeepCycleBattery", "Deep-Cycle Battery", "Batterie stationnaire"),
    ("LiveWire.BatteryAlarmKit", "Low Battery Alarm Kit", "Alarme de batterie faible en kit"),
]:
    add("ItemName", k, en, fr)

# Recipes (key = recipe name).
for k, en, fr in [
    ("LWMakeVoltageTester", "Make Voltage Tester", "Fabriquer un testeur de tension"),
    ("LWSalvageSolarCell", "Salvage Solar Cell", "Récupérer une cellule photovoltaïque"),
    ("LWMakeSolarCellFromScrap", "Make Solar Cell from Scrap", "Fabriquer une cellule photovoltaïque"),
    ("LWMakeSolarPanelKit", "Make Solar Panel Kit", "Fabriquer un panneau photovoltaïque"),
    ("LWMakeInverterKit", "Make Inverter Kit", "Fabriquer un onduleur"),
    ("LWMakeHeavyInverterKit", "Make Heavy Inverter Kit", "Fabriquer un onduleur renforcé"),
    ("LWMakeWindTurbineKit", "Make Wind Turbine Kit", "Fabriquer une éolienne"),
    ("LWMakePowerBankKit", "Make Power Bank Kit", "Fabriquer une powerbank"),
    ("LWMakeBreakerKit", "Make Circuit Breaker Kit", "Fabriquer un disjoncteur"),
    ("LWMakeDeepCycleBattery", "Make Deep-Cycle Battery", "Fabriquer une batterie stationnaire"),
    ("LWMakeBatteryAlarmKit", "Make Low Battery Alarm Kit", "Fabriquer une alarme de batterie faible"),
]:
    add("Recipes", k, en, fr)

for k, en, fr in [
    ("ContextMenu_LW_Root", "Live Wire", "Live Wire"),
    ("ContextMenu_LW_Measure", "Measure", "Mesurer"),
    ("ContextMenu_LW_Install", "Install here: %1", "Installer ici : %1"),
    ("ContextMenu_LW_Inspect", "Inspect", "Inspecter"),
    ("ContextMenu_LW_Link", "Connect to the inverter", "Raccorder à l'onduleur"),
    ("ContextMenu_LW_Unlink", "Disconnect", "Débrancher"),
    ("ContextMenu_LW_Repair", "Repair", "Réparer"),
    ("ContextMenu_LW_Overhaul", "Overhaul", "Remettre à neuf"),
    ("ContextMenu_LW_ClearSnow", "Clear the snow", "Déneiger"),
    ("ContextMenu_LW_Dismantle", "Dismantle", "Démonter"),
    ("ContextMenu_LW_Dashboard", "Open the dashboard", "Ouvrir le tableau de bord"),
    ("ContextMenu_LW_TurnOn", "Turn On", "Allumer"),
    ("ContextMenu_LW_TurnOff", "Turn Off", "Éteindre"),
    ("ContextMenu_LW_Reset", "Reset", "Réarmer"),
    ("ContextMenu_LW_Recondition", "Recondition battery", "Reconditionner la batterie"),
]:
    add("ContextMenu", k, en, fr)

for k, en, fr in [
    ("Tooltip_LW_NeedLevel", "Requires Electrical level %1.", "Il faut Électricité niv. %1."),
    ("Tooltip_LW_NeedScrewdriver", "Requires a screwdriver.", "Il faut un tournevis."),
    ("Tooltip_LW_NeedParts", "Requires electronics scrap and electric wire.", "Il faut des déchets électroniques et du fil électrique."),
    ("Tooltip_LW_NeedWire", "Requires %1 electric wire(s).", "Il faut %1 fil(s) électrique(s)."),
    ("Tooltip_LW_NeedWater", "Requires half a litre of water.", "Il faut un demi-litre d'eau."),
    ("Tooltip_LW_NeedOutdoor", "Must be installed under the open sky.", "Doit être installé à ciel ouvert."),
    ("Tooltip_LW_NeedFloor", "Needs a free floor tile.", "Il faut une case de sol libre."),
    ("Tooltip_LW_NeedWall", "Must be mounted on a wall.", "Doit être fixé sur un mur."),
    ("Tooltip_LW_Occupied", "There is already a Live Wire device here.", "Il y a déjà un appareil Live Wire ici."),
    ("Tooltip_LW_NoInverterInRange", "No inverter within cable range.", "Aucun onduleur à portée de câble."),
    ("Tooltip_LW_NotABattery", "This is not a usable battery.", "Ce n'est pas une batterie utilisable."),
    ("Tooltip_LW_DeadBattery", "This battery is dead.", "Cette batterie est morte."),
    ("Tooltip_LW_TooGood", "This battery is in good condition already.", "Cette batterie est déjà en bon état."),
    ("Tooltip_LW_EmptyFirst", "Empty it first.", "Videz-la d'abord."),
    ("Tooltip_LW_PowerBankKit", "Stores up to 4 car or deep-cycle batteries. Opens like a crate (Electrical 2).", "Accueille jusqu'à 4 batteries de voiture ou stationnaires. S'ouvre comme une caisse (Électricité 2)."),
    ("Tooltip_LW_TooFar", "Too far away.", "Trop loin."),
    ("Tooltip_LW_AlreadyLinked", "Already connected to this inverter.", "D\u00e9j\u00e0 raccord\u00e9 \u00e0 cet onduleur."),
    ("Tooltip_LW_Invalid", "Not possible.", "Impossible."),
    ("Tooltip_LW_Safehouse", "Not allowed in this safehouse.", "Interdit dans cette safehouse."),
    ("Tooltip_LW_TurnOffFirst", "Turn the inverter off first.", "Éteignez d'abord l'onduleur."),
    ("Tooltip_LW_NeedOverhaul", "Only an overhaul can improve it further.", "Seule une remise à neuf peut l'améliorer encore."),
    ("Tooltip_LW_OneOptionPerGrid", "This network already has one.", "Ce réseau en a déjà un."),
    ("Tooltip_LW_VoltageTester", "Right-click a tile to measure its power.", "Clic droit sur une case pour mesurer le courant."),
    ("Tooltip_LW_SolarPanelKit", "Source. Install it under the open sky (Electrical 3).", "Source. À installer à ciel ouvert (Électricité 3)."),
    ("Tooltip_LW_WindTurbineKit", "Source. Install it under the open sky, higher is better (Electrical 6).", "Source. À installer à ciel ouvert, plus c'est haut, mieux c'est (Électricité 6)."),
    ("Tooltip_LW_InverterKit", "Converts the power of the sources and batteries for the house. 1500 W (Electrical 5).", "Convertit le courant des sources et des batteries pour la maison. 1500 W (Électricité 5)."),
    ("Tooltip_LW_HeavyInverterKit", "Inverter. 3000 W (Electrical 8).", "Onduleur. 3000 W (Électricité 8)."),
    ("Tooltip_LW_BreakerKit", "Mounted on a wall: an overload no longer damages the inverter (Electrical 3).", "Se fixe au mur : une surcharge n'abîme plus l'onduleur (Électricité 3)."),
    ("Tooltip_LW_BatteryAlarmKit", "Beeps and warns nearby players when the batteries fall below 20%% (Electrical 2).", "Bipe et pr\u00e9vient les joueurs proches quand les batteries passent sous 20 %% (\u00c9lectricit\u00e9 2)."),
    ("Tooltip_LW_DeepCycleBattery", "Stores 1.5 kWh and lasts four times longer than a car battery.", "Stocke 1,5 kWh et dure quatre fois plus qu'une batterie de voiture."),
]:
    add("Tooltip", k, en, fr)

for k, en, fr in [
    ("IGUI_LW_Model_SolarPanel", "Solar panel", "Panneau photovoltaïque"),
    ("IGUI_LW_Model_WindTurbine", "Wind turbine", "Éolienne"),
    ("IGUI_LW_Model_Inverter", "Inverter", "Onduleur"),
    ("IGUI_LW_Model_HeavyInverter", "Heavy inverter", "Onduleur renforcé"),
    ("IGUI_LW_Section_Balance", "Production and consumption", "Production et consommation"),
    ("IGUI_LW_Section_Batteries", "Batteries (%1 power bank(s))", "Batteries (%1 powerbank(s))"),
    ("IGUI_LW_Section_House", "Powered house", "Maison alimentée"),
    ("IGUI_LW_Family_Solar", "Solar", "Solaire"),
    ("IGUI_LW_Family_Wind", "Wind", "Éolien"),
    ("IGUI_LW_Family_Hydro", "Hydro", "Hydraulique"),
    ("IGUI_LW_Family_Line", "%1: %2 source(s), %3 W", "%1 : %2 source(s), %3 W"),
    ("IGUI_LW_Family_Line_Planned", "%1: coming in a later version", "%1 : dans une prochaine version"),
    ("IGUI_LW_Snow", "(snow %1%%)", "(neige %1 %%)"),
    ("IGUI_LW_Coverage", "Every appliance within %1 tiles of the inverter, %2 floors up and down, is powered. No wiring needed.", "Tous les appareils à moins de %1 cases de l'onduleur, sur %2 étages au-dessus et en dessous, sont alimentés. Aucun câblage à faire."),
    ("IGUI_LW_NoAppliance", "no appliance in use", "aucun appareil en marche"),
    ("IGUI_LW_Appliance_Line", "%1: %2, %3 W", "%1 : %2, %3 W"),
    ("IGUI_LW_Appliance_fridge", "Fridges and freezers", "Réfrigérateurs et congélateurs"),
    ("IGUI_LW_Appliance_light", "Lights", "Lumières"),
    ("IGUI_LW_Appliance_tv", "Televisions", "Télévisions"),
    ("IGUI_LW_Appliance_radio", "Radios", "Radios"),
    ("IGUI_LW_Appliance_stove", "Stoves and microwaves", "Cuisinières et micro-ondes"),
    ("IGUI_LW_Appliance_laundry", "Washers and dryers", "Lave-linge et sèche-linge"),
    ("IGUI_LW_Appliance_charger", "Battery chargers", "Chargeurs de batterie"),
    ("IGUI_LW_Appliance_other", "Other appliances", "Autres appareils"),
    ("IGUI_LW_Model_PowerBank", "Power bank", "Powerbank"),
    ("IGUI_ContainerTitle_livewirepowerbank", "Power bank", "Powerbank"),
    ("IGUI_LW_TooManyBatteries", "%1 battery(ies) not counted: a power bank holds 4.", "%1 batterie(s) non comptée(s) : une powerbank en accueille 4."),
    ("IGUI_LW_Model_Breaker", "Circuit breaker", "Disjoncteur"),
    ("IGUI_LW_State_on", "running", "en marche"),
    ("IGUI_LW_State_off", "off", "arrêté"),
    ("IGUI_LW_State_tripped", "tripped (overload)", "disjoncté (surcharge)"),
    ("IGUI_LW_State_broken", "broken", "en panne"),
    ("IGUI_LW_State_idle", "no energy", "à vide"),
    ("IGUI_LW_State_ok", "ok", "en service"),
    ("IGUI_LW_Dashboard_Title", "Live Wire network", "Réseau Live Wire"),
    ("IGUI_LW_Waiting", "Waiting for data...", "En attente des données..."),
    ("IGUI_LW_Inverter_Line", "%1: %2 (condition %3)", "%1 : %2 (état %3)"),
    ("IGUI_LW_Demand_Line", "Demand: %1 W / %2 W max", "Demande : %1 W / %2 W max"),
    ("IGUI_LW_Production_Line", "Production: %1 W", "Production : %1 W"),
    ("IGUI_LW_Stock_Line", "Stock: %1 / %2 kWh (%3%%)", "Stock : %1 / %2 kWh (%3 %%)"),
    ("IGUI_LW_NoBattery", "No battery: only the current production is delivered.", "Aucune batterie : seule la production du moment est fournie."),
    ("IGUI_LW_Autonomy", "Autonomy: about %1 h", "Autonomie : environ %1 h"),
    ("IGUI_LW_Lost", "Production lost (batteries full): %1 kWh", "Production perdue (batteries pleines) : %1 kWh"),
    ("IGUI_LW_Alert_Overload", "Warning: close to overload!", "Attention : surcharge proche !"),
    ("IGUI_LW_Sources", "Sources", "Sources"),
    ("IGUI_LW_Batteries", "Batteries", "Batteries"),
    ("IGUI_LW_Options", "Equipment", "Équipements"),
    ("IGUI_LW_None", "none", "aucune"),
    ("IGUI_LW_Source_Line", "%1: %2 W (condition %3)", "%1 : %2 W (état %3)"),
    ("IGUI_LW_Battery_Line", "%1: %2%% (condition %3)", "%1 : %2 %% (état %3)"),
    ("IGUI_LW_Option_Line", "%1 (condition %2)", "%1 (état %2)"),
    ("IGUI_LW_Installed", "%1 installed.", "%1 installé."),
    ("IGUI_LW_InstallFailed", "Installation failed, the kit is damaged.", "Installation ratée, le kit est abîmé."),
    ("IGUI_LW_Linked", "Connected.", "Raccordé."),
    ("IGUI_LW_Unlinked", "Disconnected.", "Débranché."),
    ("IGUI_LW_Repaired", "Repaired, condition %1.", "Réparé, état %1."),
    ("IGUI_LW_RepairFailed", "Repair failed, the parts are lost.", "Réparation ratée, les pièces sont perdues."),
    ("IGUI_LW_Reconditioned", "Battery reconditioned, condition %1.", "Batterie reconditionnée, état %1."),
    ("IGUI_LW_Tripped", "The inverter tripped (overload).", "L'onduleur a disjoncté (surcharge)."),
    ("IGUI_LW_StillOverloaded", "Still overloaded: turn some appliances off first.", "Toujours en surcharge : éteignez d'abord des appareils."),
    ("IGUI_LW_Broken", "The inverter is broken.", "L'onduleur est en panne."),
    ("IGUI_LW_InspectSource", "%1: condition %2, %3 W delivered (%4 W raw)", "%1 : état %2, %3 W fournis (%4 W bruts)"),
    ("IGUI_LW_InspectInverter", "%1: condition %2, %3", "%1 : état %2, %3"),
    ("IGUI_LW_InspectOther", "%1: condition %2", "%1 : état %2"),
    ("IGUI_LW_Measure_NoPower", "No power.", "Pas de courant."),
    ("IGUI_LW_Measure_Powered", "Power: yes.", "Courant : oui."),
    ("IGUI_LW_Measure_Source_Grid", "Power from the public grid.", "Courant du réseau public."),
    ("IGUI_LW_Measure_Source_Generator", "Power from a generator.", "Courant d'un générateur."),
    ("IGUI_LW_Measure_Source_LiveWire", "Power from a Live Wire inverter.", "Courant d'un onduleur Live Wire."),
    ("IGUI_LW_Measure_Draw", "This appliance draws %1 W.", "Cet appareil consomme %1 W."),
    ("IGUI_LW_Measure_Grid", "Network: %1 W produced, %2 W used, %3 kWh stored, autonomy %4 h", "Réseau : %1 W produits, %2 W consommés, %3 kWh stockés, autonomie %4 h"),
]:
    add("IG_UI", k, en, fr)

# Backup generator, management computer, low battery alarm.
for k, en, fr in [
    ("IGUI_LW_Model_BackupGenerator", "Backup generator", "G\u00e9n\u00e9rateur de secours"),
    ("IGUI_LW_Model_ManagementComputer", "Management computer", "Ordinateur de gestion"),
    ("IGUI_LW_Model_BatteryAlarm", "Low battery alarm", "Alarme de batterie faible"),
    ("IGUI_LW_Section_Backup", "Backup power", "Alimentation de secours"),
    ("IGUI_LW_Backup_Line", "Generator: %1, %2 W", "G\u00e9n\u00e9rateur : %1, %2 W"),
    ("IGUI_LW_Backup_running", "charging the batteries", "recharge les batteries"),
    ("IGUI_LW_Backup_standby", "on standby", "en veille"),
    ("IGUI_LW_Backup_nofuel", "out of fuel", "plus de carburant"),
    ("IGUI_LW_Backup_unplugged", "not connected (vanilla Connect option)", "non branch\u00e9 (option vanilla Brancher)"),
    ("IGUI_LW_Backup_broken", "broken", "en panne"),
    ("IGUI_LW_Backup_Fuel", "Fuel: %1%%", "Carburant : %1 %%"),
    ("IGUI_LW_Backup_Thresholds", "Starts below %1%% of battery, stops at %2%%.", "D\u00e9marre sous %1 %% de batterie, s'arr\u00eate \u00e0 %2 %%."),
    ("IGUI_LW_Section_Computer", "Management computer", "Ordinateur de gestion"),
    ("IGUI_LW_Computer_None", "Connect a desktop computer (Electrical 6) to see the history and the forecast.", "Raccordez un ordinateur de bureau (\u00c9lectricit\u00e9 6) pour voir l'historique et la pr\u00e9vision."),
    ("IGUI_LW_Computer_Off", "The computer has no power.", "L'ordinateur n'est pas aliment\u00e9."),
    ("IGUI_LW_Computer_NoHistory", "Recording... (one point per hour)", "Enregistrement... (un point par heure)"),
    ("IGUI_LW_Computer_Shed", "Load shedding: lights are switched off below 15%% of battery.", "D\u00e9lestage : les lumi\u00e8res sont \u00e9teintes sous 15 %% de batterie."),
    ("IGUI_LW_History_Production", "Production, last %1 h (peak %2 W)", "Production, %1 derni\u00e8res heures (pic %2 W)"),
    ("IGUI_LW_History_Demand", "Consumption", "Consommation"),
    ("IGUI_LW_History_Stock", "Battery stock", "Stock des batteries"),
    ("IGUI_LW_Forecast_Holds", "Forecast: the batteries will last until sunrise (in %1 h).", "Pr\u00e9vision : les batteries tiendront jusqu'\u00e0 l'aube (dans %1 h)."),
    ("IGUI_LW_Forecast_Short", "Forecast: about %1 h left, sunrise in %2 h.", "Pr\u00e9vision : environ %1 h restantes, aube dans %2 h."),
    ("IGUI_LW_Forecast_Surplus", "Forecast: production covers the consumption.", "Pr\u00e9vision : la production couvre la consommation."),
    ("IGUI_LW_Shed", "Low battery: the computer switched the lights off.", "Batterie faible : l'ordinateur a \u00e9teint les lumi\u00e8res."),
    ("IGUI_LW_Alarm_On", "Low battery alarm: ringing", "Alarme de batterie faible : d\u00e9clench\u00e9e"),
    ("IGUI_LW_Alarm_Armed", "Low battery alarm: armed", "Alarme de batterie faible : en veille"),
    ("IGUI_LW_LowBattery", "Low battery: %1%% left!", "Batterie faible : il reste %1 %% !"),
]:
    add("IG_UI", k, en, fr)

SANDBOX = [
    ("PowerScale", "Power scale", "Échelle de puissance",
     "Multiplies the consumption of every appliance (1 = a fridge-freezer draws 130 W).",
     "Multiplie la consommation de chaque appareil (1 = un réfrigérateur-congélateur consomme 130 W)."),
    ("SolarMultiplier", "Solar production", "Production solaire",
     "Multiplier of the solar panel production.", "Multiplicateur de la production des panneaux photovoltaïques."),
    ("WindMultiplier", "Wind production", "Production éolienne",
     "Multiplier of the wind turbine production.", "Multiplicateur de la production des éoliennes."),
    ("BatteryCapacityMultiplier", "Battery capacity", "Capacité des batteries",
     "Multiplier of the capacity of every battery.", "Multiplicateur de la capacité de toutes les batteries."),
    ("BatteryWearMultiplier", "Battery wear", "Usure des batteries",
     "0 disables battery wear.", "0 désactive l'usure des batteries."),
    ("DeviceWearMultiplier", "Device wear", "Usure des appareils",
     "Wear of sources, inverters and equipment. 0 disables it.", "Usure des sources, des onduleurs et des équipements. 0 la désactive."),
    ("InverterNoiseRadius", "Inverter noise radius", "Rayon du bruit de l'onduleur",
     "Radius in tiles of the hum heard by zombies. 0 = silent.", "Rayon en cases du bourdonnement entendu par les zombies. 0 = silencieux."),
    ("LinkRange", "Cable range", "Portée des câbles",
     "Maximum distance in tiles between a device and its inverter.", "Distance maximale en cases entre un appareil et son onduleur."),
    ("WirePerTiles", "Tiles per electric wire", "Cases par fil électrique",
     "One electric wire is used per this many tiles of cable. 0 = free cabling.", "Un fil électrique est utilisé pour ce nombre de cases de câble. 0 = câblage gratuit."),
    ("StormDamage", "Storm damage", "Dégâts d'orage",
     "Thunderstorms and very strong winds damage solar panels and wind turbines.", "Les orages et les vents très forts abîment les panneaux et les éoliennes."),
    ("XPMultiplier", "Electrical experience", "Expérience d'électricité",
     "Multiplier of the experience given by Live Wire actions.", "Multiplicateur de l'expérience donnée par les actions Live Wire."),
    ("SkillGates", "Skill requirements", "Niveaux requis",
     "When disabled, no Electrical level is required.", "Désactivé : aucun niveau d'Électricité n'est requis."),
    ("SimulateUnloaded", "Run without players nearby", "Fonctionnement sans joueur",
     "Production, consumption and wear go on when no player is nearby.", "Production, consommation et usure continuent quand aucun joueur n'est à proximité."),
    ("BackupStartPercent", "Backup start (percent)", "D\u00e9marrage du secours (pourcentage)",
     "A backup generator starts when the batteries fall below this percentage.", "Un g\u00e9n\u00e9rateur de secours d\u00e9marre quand les batteries passent sous ce pourcentage."),
    ("BackupStopPercent", "Backup stop (percent)", "Arr\u00eat du secours (pourcentage)",
     "The backup generator stops once the batteries reach this percentage.", "Le g\u00e9n\u00e9rateur de secours s'arr\u00eate quand les batteries atteignent ce pourcentage."),
]
add("Sandbox", "Sandbox_LiveWire", "Live Wire", "Live Wire")
for name, en, fr, ten, tfr in SANDBOX:
    add("Sandbox", "Sandbox_LiveWire_" + name, en, fr)
    add("Sandbox", "Sandbox_LiveWire_" + name + "_tooltip", ten, tfr)


def main():
    for lang, idx in (("EN", 0), ("FR", 1)):
        d = os.path.join(OUT, lang)
        os.makedirs(d, exist_ok=True)
        for f, keys in T.items():
            data = {k: v[idx] for k, v in keys.items()}
            with open(os.path.join(d, f + ".json"), "w", encoding="utf-8") as fh:
                json.dump(data, fh, ensure_ascii=False, indent=4)
                fh.write("\n")
    print("wrote %d files per language" % len(T))
    return 0


if __name__ == "__main__":
    sys.exit(main())
