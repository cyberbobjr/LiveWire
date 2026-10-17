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
    ("LiveWire.DeepCycleBattery", "Deep-Cycle Battery", "Batterie stationnaire"),
    ("LiveWire.SoundproofKit", "Inverter Soundproofing Kit", "Kit d'insonorisation d'onduleur"),
    ("LiveWire.MonitorDisk", "Disk: Live Wire Management Software", "Disque : logiciel de gestion Live Wire"),
    ("Base.Mov_LiveWire_SolarPanel", "Solar Panel", "Panneau photovoltaïque"),
    ("Base.Mov_LiveWire_WindTurbine", "Wind Turbine", "Éolienne"),
    ("Base.Mov_LiveWire_WaterWheel", "Water Wheel", "Roue à aubes"),
    ("Base.Mov_LiveWire_Inverter", "Inverter", "Onduleur"),
    ("Base.Mov_LiveWire_PowerBank", "Power Bank", "Powerbank"),
    ("Base.Mov_LiveWire_Breaker", "Breaker Panel", "Disjoncteur"),
    ("Base.Mov_LiveWire_BatteryAlarm", "Low Battery Alarm", "Alarme de batterie faible"),
]:
    add("ItemName", k, en, fr)

# Placed tiles and their inventory items (Translator.getMoveableDisplayName:
# GroupName + " " + CustomName with spaces as underscores, in Moveables.json).
for k, en, fr in [
    ("Live_Wire_Solar_Panel", "Solar Panel", "Panneau photovoltaïque"),
    ("Live_Wire_Wind_Turbine", "Wind Turbine", "Éolienne"),
    ("Live_Wire_Water_Wheel", "Water Wheel", "Roue à aubes"),
    ("Live_Wire_Inverter", "Inverter", "Onduleur"),
    ("Live_Wire_Power_Bank", "Power Bank", "Powerbank"),
    ("Live_Wire_Breaker_Panel", "Breaker Panel", "Disjoncteur"),
    ("Live_Wire_Battery_Alarm", "Low Battery Alarm", "Alarme de batterie faible"),
]:
    add("Moveables", k, en, fr)

# Recipes (key = recipe name).
for k, en, fr in [
    ("LWMakeVoltageTester", "Make Voltage Tester", "Fabriquer un testeur de tension"),
    ("LWSalvageSolarCell", "Dismantle Calculator", "Démonter une calculatrice"),
    ("LWMakeSolarCellFromScrap", "Make Solar Cell from Scrap", "Fabriquer une cellule photovoltaïque"),
    ("LWMakeSolarPanelKit", "Make Solar Panel", "Fabriquer un panneau photovoltaïque"),
    ("LWMakeInverterKit", "Make Inverter", "Fabriquer un onduleur"),
    ("LWMakeWindTurbineKit", "Make Wind Turbine", "Fabriquer une éolienne"),
    ("LWMakeWaterWheel", "Make Water Wheel", "Fabriquer une roue à aubes"),
    ("LWMakePowerBankKit", "Make Power Bank", "Fabriquer une powerbank"),
    ("LWMakeBreakerKit", "Make Breaker Panel", "Fabriquer un disjoncteur"),
    ("LWMakeSoundproofKit", "Make Inverter Soundproofing Kit", "Fabriquer un kit d'insonorisation d'onduleur"),
    ("LWMakeDeepCycleBattery", "Make Deep-Cycle Battery", "Fabriquer une batterie stationnaire"),
    ("LWMakeBatteryAlarmKit", "Make Low Battery Alarm", "Fabriquer une alarme de batterie faible"),
]:
    add("Recipes", k, en, fr)

for k, en, fr in [
    ("ContextMenu_LW_Root", "Live Wire", "Live Wire"),
    ("ContextMenu_LW_Measure", "Measure", "Mesurer"),
    ("ContextMenu_LW_Inspect", "Inspect", "Inspecter"),
    ("ContextMenu_LW_Unlink", "Disconnect from the inverter", "Débrancher de l'onduleur"),
    ("ContextMenu_LW_Muffle", "Soundproof the inverter", "Insonoriser l'onduleur"),
    ("ContextMenu_LW_Unmuffle", "Remove the soundproofing", "Retirer l'insonorisation"),
    ("ContextMenu_LW_Panel", "Open the inverter screen", "Ouvrir l'écran de l'onduleur"),
    ("ContextMenu_LW_ShowRange", "Show the powered area", "Afficher la zone alimentée"),
    ("ContextMenu_LW_HideRange", "Hide the powered area", "Masquer la zone alimentée"),
    ("ContextMenu_LW_ResetBreaker", "Reset the breaker", "Réarmer le disjoncteur"),
    ("ContextMenu_LW_AckAlarm", "Silence the alarm", "Couper la sonnerie"),
    ("ContextMenu_LW_Software", "Open the Live Wire management software", "Ouvrir le logiciel de gestion Live Wire"),
    ("ContextMenu_LW_InstallSoftware", "Install the Live Wire software", "Installer le logiciel Live Wire"),
    ("ContextMenu_LW_LinkTo", "Connect to an inverter", "Raccorder à un onduleur"),
    ("ContextMenu_LW_InverterAt", "Inverter %1 tiles away (%2 wire(s))", "Onduleur à %1 cases (%2 fil(s))"),
    ("ContextMenu_LW_NoInverter", "No inverter within %1 tiles", "Aucun onduleur à moins de %1 cases"),
    ("ContextMenu_LW_LinkedTo", "Connected to the inverter %1 tiles away", "Raccordé à l'onduleur à %1 cases"),
    ("ContextMenu_LW_LinkedFar", "Connected to an inverter out of sight", "Raccordé à un onduleur hors de vue"),
    ("ContextMenu_LW_NotLinked", "Not connected", "Non raccordé"),
    ("ContextMenu_LW_LinkDevice", "Connect equipment", "Raccorder un équipement"),
    ("ContextMenu_LW_UnlinkDevice", "Disconnect equipment", "Débrancher un équipement"),
    ("ContextMenu_LW_DeviceAt", "%1, %2 tiles away (%3 wire(s))", "%1, à %2 cases (%3 fil(s))"),
    ("ContextMenu_LW_LinkedDeviceAt", "%1, %2 tiles away", "%1, à %2 cases"),
    ("ContextMenu_LW_NothingToLink", "Nothing to connect within %1 tiles", "Rien à raccorder à moins de %1 cases"),
    ("ContextMenu_LW_NothingLinked", "No equipment connected", "Aucun équipement raccordé"),
    ("ContextMenu_LW_Members", "%1 equipment connected", "%1 équipement(s) raccordé(s)"),
    ("ContextMenu_LW_Repair", "Repair", "Réparer"),
    ("ContextMenu_LW_Overhaul", "Overhaul", "Remettre à neuf"),
    ("ContextMenu_LW_ClearSnow", "Clear the snow", "Déneiger"),
    ("ContextMenu_LW_TurnOn", "Turn On", "Allumer"),
    ("ContextMenu_LW_TurnOff", "Turn Off", "Éteindre"),
    ("ContextMenu_LW_Reset", "Reset", "Réarmer"),
    ("ContextMenu_LW_Recondition", "Recondition battery", "Reconditionner la batterie"),
    ("ContextMenu_LW_Debug", "Debug", "Debug"),
    ("ContextMenu_LW_Debug_spawnKit", "Give a full test kit", "Donner un kit de test complet"),
    ("ContextMenu_LW_Debug_dump", "Show the network state (console)", "Afficher l'\u00e9tat du r\u00e9seau (console)"),
    ("ContextMenu_LW_Debug_battery100", "Batteries to 100%%", "Batteries \u00e0 100 %%"),
    ("ContextMenu_LW_Debug_battery50", "Batteries to 50%%", "Batteries \u00e0 50 %%"),
    ("ContextMenu_LW_Debug_battery15", "Batteries to 15%% (alarm, backup)", "Batteries \u00e0 15 %% (alarme, secours)"),
    ("ContextMenu_LW_Debug_battery0", "Batteries empty", "Batteries vides"),
    ("ContextMenu_LW_Debug_advance1", "Run the simulation for 1 hour", "Faire tourner la simulation 1 heure"),
    ("ContextMenu_LW_Debug_advance12", "Run the simulation for 12 hours", "Faire tourner la simulation 12 heures"),
    ("ContextMenu_LW_Debug_repairAll", "Repair the whole network", "R\u00e9parer tout le r\u00e9seau"),
    ("ContextMenu_LW_Debug_damageInverter", "Damage the inverter (condition 10)", "Ab\u00eemer l'onduleur (\u00e9tat 10)"),
    ("ContextMenu_LW_Debug_trip", "Trip the inverter", "Faire disjoncter l'onduleur"),
    ("ContextMenu_LW_Debug_refuel", "Fill the backup generator", "Remplir le g\u00e9n\u00e9rateur de secours"),
    ("ContextMenu_LW_Debug_reanchor", "Rebuild the appliance list and the power area", "Reconstruire la liste des appareils et la zone aliment\u00e9e"),
]:
    add("ContextMenu", k, en, fr)

for k, en, fr in [
    ("Tooltip_LW_NeedLevel", "Requires Electrical level %1.", "Il faut Électricité niv. %1."),
    ("Tooltip_LW_NeedScrewdriver", "Requires a screwdriver.", "Il faut un tournevis."),
    ("Tooltip_LW_NeedParts", "Requires electronics scrap and electric wire.", "Il faut des déchets électroniques et du fil électrique."),
    ("Tooltip_LW_NeedWire", "Requires %1 electric wire(s).", "Il faut %1 fil(s) électrique(s)."),
    ("Tooltip_LW_NeedWater", "Requires half a litre of water.", "Il faut un demi-litre d'eau."),
    ("Tooltip_LW_NeedOutdoor", "Must be placed outdoors, under the open sky.", "Doit être posé dehors, à ciel ouvert."),
    ("Tooltip_LW_NeedWaterSide", "Must be placed on the bank, next to water.", "Doit être posée sur la berge, au bord de l'eau."),
    ("Tooltip_LW_NoInverterInRange", "No inverter within cable range.", "Aucun onduleur à portée de câble."),
    ("Tooltip_LW_NotABattery", "This is not a usable battery.", "Ce n'est pas une batterie utilisable."),
    ("Tooltip_LW_DeadBattery", "This battery is dead.", "Cette batterie est morte."),
    ("Tooltip_LW_TooGood", "This battery is in good condition already.", "Cette batterie est déjà en bon état."),
    ("Tooltip_LW_EmptyFirst", "Empty it first.", "Videz-la d'abord."),
    ("Tooltip_LW_TooFar", "Too far away.", "Trop loin."),
    ("Tooltip_LW_AlreadyLinked", "Already connected to this inverter.", "D\u00e9j\u00e0 raccord\u00e9 \u00e0 cet onduleur."),
    ("Tooltip_LW_Invalid", "Not possible.", "Impossible."),
    ("Tooltip_LW_Safehouse", "Not allowed in this safehouse.", "Interdit dans cette safehouse."),
    ("Tooltip_LW_TurnOffFirst", "Turn the inverter off first.", "Éteignez d'abord l'onduleur."),
    ("Tooltip_LW_NeedOverhaul", "Only an overhaul can improve it further.", "Seule une remise à neuf peut l'améliorer encore."),
    ("Tooltip_LW_OneOptionPerGrid", "This network already has one.", "Ce réseau en a déjà un."),
    ("Tooltip_LW_SoundproofKit", "Fitted on an inverter: no more hum, and zombies no longer hear it. The inverter runs warmer and wears 25%% faster.", "Se pose sur un onduleur : plus de bourdonnement, et les zombies ne l'entendent plus. L'onduleur chauffe davantage et s'use 25 %% plus vite."),
    ("Tooltip_LW_NeedSoundproofKit", "Requires a soundproofing kit.", "Il faut un kit d'insonorisation."),
    ("Tooltip_LW_MonitorDisk", "Installs the Live Wire management app on a Computer Mod computer or laptop.", "Installe l'application de gestion Live Wire sur un ordinateur ou un portable du Computer Mod."),
    ("Tooltip_LW_NeedDisk", "Requires the Live Wire software disk.", "Il faut le disque du logiciel Live Wire."),
    ("Tooltip_LW_NeedSoftware", "Install the Live Wire software (disk) on this computer first.", "Installez d'abord le logiciel Live Wire (disque) sur cet ordinateur."),
    ("Tooltip_LW_VoltageTester", "Right-click a tile to measure its power.", "Clic droit sur une case pour mesurer le courant."),
    ("Tooltip_LW_DeepCycleBattery", "Stores 1.5 kWh and lasts four times longer than a car battery.", "Stocke 1,5 kWh et dure quatre fois plus qu'une batterie de voiture."),
]:
    add("Tooltip", k, en, fr)

for k, en, fr in [
    ("IGUI_LW_Model_SolarPanel", "Solar panel", "Panneau photovoltaïque"),
    ("IGUI_LW_Model_WindTurbine", "Wind turbine", "Éolienne"),
    ("IGUI_LW_Model_WaterWheel", "Water wheel", "Roue à aubes"),
    ("IGUI_LW_Model_Inverter", "Inverter", "Onduleur"),
    ("IGUI_LW_Section_Balance", "Production and consumption", "Production et consommation"),
    ("IGUI_LW_Section_Batteries", "Batteries (%1 power bank(s))", "Batteries (%1 powerbank(s))"),
    ("IGUI_LW_Section_House", "Powered house", "Maison alimentée"),
    ("IGUI_LW_Family_Solar", "Solar", "Solaire"),
    ("IGUI_LW_Family_Wind", "Wind", "Éolien"),
    ("IGUI_LW_Family_Hydro", "Hydro", "Hydraulique"),
    ("IGUI_LW_Family_Line", "%1: %2 source(s), %3 W", "%1 : %2 source(s), %3 W"),
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
    ("IGUI_LW_Linked", "Connected.", "Raccordé."),
    ("IGUI_LW_Unlinked", "Disconnected.", "Débranché."),
    ("IGUI_LW_Repaired", "Repaired, condition %1.", "Réparé, état %1."),
    ("IGUI_LW_RepairFailed", "Repair failed, the parts are lost.", "Réparation ratée, les pièces sont perdues."),
    ("IGUI_LW_Reconditioned", "Battery reconditioned, condition %1.", "Batterie reconditionnée, état %1."),
    ("IGUI_LW_Tripped", "The inverter tripped: %1 W demanded for %2 W max.", "L'onduleur a disjoncté : %1 W demandés pour %2 W max."),
    ("IGUI_LW_BreakerTripped", "The breaker tripped: %1 W demanded for %2 W max. Reset it on the breaker.", "Le disjoncteur a sauté : %1 W demandés pour %2 W max. Réarmez-le sur le disjoncteur."),
    ("IGUI_LW_Muffled", "Inverter soundproofed.", "Onduleur insonorisé."),
    ("IGUI_LW_Unmuffled", "Soundproofing removed.", "Insonorisation retirée."),
    ("IGUI_LW_BreakerReset", "Breaker reset.", "Disjoncteur réarmé."),
    ("IGUI_LW_StillOverloaded", "Still overloaded: %1 W for %2 W max. Turn some appliances off first.", "Toujours en surcharge : %1 W pour %2 W max. Éteignez d'abord des appareils."),
    ("IGUI_LW_AlarmSilenced", "Alarm silenced. Its light stays on while the battery is low.", "Sonnerie coupée. Le voyant reste allumé tant que la batterie est basse."),
    ("IGUI_LW_Scale", "Common scale: %1 W", "Échelle commune : %1 W"),
    ("IGUI_LW_Software_Title", "Live Wire management software", "Logiciel de gestion Live Wire"),
    ("IGUI_LW_App", "Live Wire", "Live Wire"),
    ("IGUI_LW_NoInverterForSoftware", "No Live Wire inverter in range.", "Aucun onduleur Live Wire à portée."),
    ("IGUI_LW_SoftwareInstalled", "Live Wire software installed.", "Logiciel Live Wire installé."),
    ("IGUI_LW_App_Name", "Live Wire Monitor", "Live Wire Monitor"),
    ("IGUI_LW_App_OS", "Live Wire OS", "Live Wire OS"),
    ("IGUI_LW_App_Booting", "Live Wire OS - starting", "Live Wire OS - démarrage"),
    ("IGUI_LW_App_Brand", "LW-486 Personal Computer", "LW-486 Personal Computer"),
    ("IGUI_LW_App_Tab_Overview", "Overview", "Vue d'ensemble"),
    ("IGUI_LW_App_Tab_Batteries", "Batteries", "Batteries"),
    ("IGUI_LW_App_Tab_Sources", "Sources", "Sources"),
    ("IGUI_LW_App_Tab_House", "House", "Maison"),
    ("IGUI_LW_App_Tab_History", "History", "Historique"),
    ("IGUI_LW_App_Tab_Equipment", "Equipment", "Équipements"),
    ("IGUI_LW_App_Tab_Overview_Short", "Overview", "Accueil"),
    ("IGUI_LW_App_Tab_Batteries_Short", "Batt.", "Batt."),
    ("IGUI_LW_App_Tab_Sources_Short", "Sources", "Sources"),
    ("IGUI_LW_App_Tab_House_Short", "House", "Maison"),
    ("IGUI_LW_App_Tab_History_Short", "History", "Histo."),
    ("IGUI_LW_App_Tab_Equipment_Short", "Equip.", "Équip."),
    ("IGUI_LW_App_Power", "Power", "Puissance"),
    ("IGUI_LW_App_Production", "Production", "Production"),
    ("IGUI_LW_App_Load", "Consumption", "Consommation"),
    ("IGUI_LW_App_Scale", "Scale: %1 W (inverter %2 W max)", "Échelle : %1 W (onduleur %2 W max)"),
    ("IGUI_LW_App_Storage", "Storage", "Stockage"),
    ("IGUI_LW_App_Inverter", "Inverter", "Onduleur"),
    ("IGUI_LW_App_Condition", "Condition: %1%%", "État : %1 %%"),
    ("IGUI_LW_App_BreakerTripped", "Breaker tripped", "Disjoncteur déclenché"),
    ("IGUI_LW_App_NoAlert", "No alert", "Aucune alerte"),
    ("IGUI_LW_App_BatteryState", "%1%% - condition %2", "%1 %% - état %2"),
    ("IGUI_LW_App_FamilyTotal", "%1 source(s) - %2 W", "%1 source(s) - %2 W"),
    ("IGUI_LW_App_SourceState", "%1 W - condition %2", "%1 W - état %2"),
    ("IGUI_LW_App_ApplianceState", "%1 - %2 W", "%1 - %2 W"),
    ("IGUI_LW_LCD_Brand", "LIVE WIRE - INVERTER 1500 W", "LIVE WIRE - ONDULEUR 1500 W"),
    ("IGUI_LW_LCD_Page_Balance", "PRODUCTION / LOAD", "PRODUCTION / CONSO"),
    ("IGUI_LW_LCD_Prod", "PROD   %1 W", "PROD   %1 W"),
    ("IGUI_LW_LCD_Load", "LOAD   %1 W / %2 W", "CONSO  %1 W / %2 W"),
    ("IGUI_LW_LCD_BarProd", "PROD", "PROD"),
    ("IGUI_LW_LCD_BarLoad", "LOAD", "CONSO"),
    ("IGUI_LW_LCD_Page_Batteries", "BATTERIES", "BATTERIES"),
    ("IGUI_LW_LCD_Stock", "CHARGE  %1%%", "CHARGE  %1 %%"),
    ("IGUI_LW_LCD_Kwh", "%1 / %2 kWh", "%1 / %2 kWh"),
    ("IGUI_LW_LCD_Autonomy", "AUTONOMY ~%1 h", "AUTONOMIE ~%1 h"),
    ("IGUI_LW_LCD_Banks", "%1 batt. in %2 power bank(s)", "%1 batt. dans %2 powerbank(s)"),
    ("IGUI_LW_LCD_NoBattery", "NO BATTERY", "AUCUNE BATTERIE"),
    ("IGUI_LW_LCD_Page_Sources", "SOURCES", "SOURCES"),
    ("IGUI_LW_LCD_Family", "%1: %2 x  %3 W", "%1 : %2 x  %3 W"),
    ("IGUI_LW_LCD_Page_House", "HOUSE", "MAISON"),
    ("IGUI_LW_LCD_Range", "Range %1 tiles, +/- %2 floors", "Rayon %1 cases, +/- %2 étages"),
    ("IGUI_LW_LCD_Page_Status", "STATUS", "ÉTAT"),
    ("IGUI_LW_LCD_Inverter", "INVERTER: %1 (%2%%)", "ONDULEUR : %1 (%2 %%)"),
    ("IGUI_LW_LCD_Breaker", "Breaker: %1", "Disjoncteur : %1"),
    ("IGUI_LW_LCD_Muffled", "Soundproofed: silent, wears 25%% faster", "Insonorisé : silencieux, s'use 25 %% plus vite"),
    ("IGUI_LW_LCD_Overload", "!! OVERLOAD !!", "!! SURCHARGE !!"),
    ("IGUI_LW_Broken", "The inverter is broken.", "L'onduleur est en panne."),
    ("IGUI_LW_InspectSource", "%1: condition %2, %3 W delivered (%4 W raw)", "%1 : état %2, %3 W fournis (%4 W bruts)"),
    ("IGUI_LW_InspectInverter", "%1: condition %2, %3", "%1 : état %2, %3"),
    ("IGUI_LW_InspectMuffled", "Soundproofed: no hum, zombies cannot hear it, wears 25%% faster.", "Insonorisé : plus de bourdonnement, les zombies ne l'entendent plus, s'use 25 %% plus vite."),
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
    ("IGUI_LW_Debug_Done", "Debug: %1 done.", "Debug : %1 fait."),
    ("IGUI_LW_Debug_NoGrid", "Debug: this device is not on a network.", "Debug : cet appareil n'est sur aucun r\u00e9seau."),
    ("IGUI_LW_Debug_Dump", "Network: %1 W produced, %2 W used, %3 / %4 kWh (details in the console)", "R\u00e9seau : %1 W produits, %2 W consomm\u00e9s, %3 / %4 kWh (d\u00e9tails dans la console)"),
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

# Player options (Options > Mods), UI.json.
for k, en, fr in [
    ("UI_LW_Options_Title", "Live Wire", "Live Wire"),
    ("UI_LW_Options_HumVolume", "Inverter hum volume (0-100)", "Volume du bourdonnement de l'onduleur (0-100)"),
    ("UI_LW_Options_HumVolume_tooltip", "0 = no hum. Only for you; heard one tile around a running inverter.", "0 = aucun bourdonnement. Pour vous seul ; il s'entend à une case autour d'un onduleur allumé."),
]:
    add("UI", k, en, fr)

SANDBOX = [
    ("PowerScale", "Power scale", "Échelle de puissance",
     "Multiplies the consumption of every appliance (1 = a fridge-freezer draws 130 W).",
     "Multiplie la consommation de chaque appareil (1 = un réfrigérateur-congélateur consomme 130 W)."),
    ("SolarMultiplier", "Solar production", "Production solaire",
     "Multiplier of the solar panel production.", "Multiplicateur de la production des panneaux photovoltaïques."),
    ("WindMultiplier", "Wind production", "Production éolienne",
     "Multiplier of the wind turbine production.", "Multiplicateur de la production des éoliennes."),
    ("HydroMultiplier", "Hydro production", "Production hydraulique",
     "Multiplier of the water wheel production.", "Multiplicateur de la production des roues à aubes."),
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
            with open(os.path.join(d, f + ".json"), "w", encoding="utf-8", newline="\n") as fh:
                json.dump(data, fh, ensure_ascii=False, indent=4)
                fh.write("\n")
    print("wrote %d files per language" % len(T))
    return 0


if __name__ == "__main__":
    sys.exit(main())
