> Version francaise : [[Tables de butin|Tables-de-butin]]

# Loot Tables

Live Wire adds three items to the vanilla loot lists, and a few other ways to get solar cells.

## How to read the tables

Project Zomboid tests each item independently at each roll of a container list. A **weight** of W gives about W % per roll at normal loot rarity (before sandbox loot settings and zombie density). The **Rolls** column is the number of rolls of that vanilla list.

Approximate chance per container = 1 - (1 - W / 100)^Rolls. For placeable furniture items like the solar panel, vanilla applies the "Other" loot modifier (0.6 at normal rarity).

## Solar cell (`LiveWire.SolarCell`, always)

| Vanilla list | Where | Weight | Rolls | Chance per container |
|---|---|---|---|---|
| GarageTools | Garage tool storage | 2 | 4 | 7.8 % |
| CrateTools | Tool crates | 1 | 4 | 3.9 % |
| GarageMetalwork | Garage metalwork storage | 1 | 4 | 3.9 % |
| MechanicShelfElectric | Mechanic shop, electrical shelf | 2 | 4 | 7.8 % |
| ElectricianTools | Electrician's tools | 3 | 3 | 8.7 % |
| MetalShopTools | Metal shop tools | 1 | 4 | 3.9 % |
| WireFactoryElectric | Wire factory, electrical | 2 | 4 | 7.8 % |
| ToolStoreMisc | Hardware store, miscellaneous | 2 | 4 | 7.8 % |

## Ready-made solar panel (`Base.Mov_LiveWire_SolarPanel`, always; furniture, x 0.6 at normal rarity)

| Vanilla list | Where | Weight | Rolls | Chance per container |
|---|---|---|---|---|
| GarageTools | Garage tool storage | 0.3 | 4 | 0.7 % |
| CrateTools | Tool crates | 0.3 | 4 | 0.7 % |
| GarageMetalwork | Garage metalwork storage | 0.2 | 4 | 0.5 % |
| ToolStoreMisc | Hardware store, miscellaneous | 0.5 | 4 | 1.2 % |
| ToolStoreTools | Hardware store, tools | 0.3 | 4 | 0.7 % |

## Management software disk (`LiveWire.MonitorDisk`, only when the Computer Mod is active)

| Vanilla list | Where | Weight | Rolls | Chance per container |
|---|---|---|---|---|
| ElectronicStoreComputers | Electronics store, computers | 2 | 1 | 2.0 % |
| CrateComputer | Computer crates | 2 | 4 | 7.8 % |
| BookstoreComputer | Bookstore, computer section | 1 | 4 | 3.9 % |
| UniversityDesk_Computer | University desk, computing | 1 | 4 | 3.9 % |
| UniversityDesk_Electrical | University desk, electrical | 2 | 4 | 7.8 % |
| OfficeDesk | Office desks | 0.3 | 4 | 1.2 % |

## Other ways to get solar cells

- Dismantle a calculator: 1 solar cell each, no level required.
- At Electrical level 8, make a solar cell from 5 electronics scrap + 1 aluminum.

## See also

[[Recipes|Recipes]] - [[Equipment|Equipment]] - [[Inverter Screen and Software|Inverter-Screen-and-Software]] - [[Multiplayer and FAQ|Multiplayer-and-FAQ]]
