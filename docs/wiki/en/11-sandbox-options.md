> Version française : [Options sandbox](../fr/11-options-sandbox.md)

# Sandbox Options

Server and game settings are on the **LiveWire** page of the sandbox options.

| Option | Default | Range | Effect |
|---|---|---|---|
| `ConsumptionProfile` | Game values | Ultra-realistic 1993, Realistic 1993, Game values, Comfort | Power drawn by switched-on appliances; see the table in [Production and Calculations](04-production-and-calculations.md#appliance-consumption) |
| `PowerScale` | 1.0 | 0.1-10 | Multiplies the consumption given by the profile (1 = no change) |
| `SolarMultiplier` / `WindMultiplier` / `HydroMultiplier` | 1.0 | 0-10 | Production per source family |
| `BatteryCapacityMultiplier` | 1.0 | 0.1-10 | Battery capacity |
| `BatteryWearMultiplier` / `DeviceWearMultiplier` | 1.0 | 0-10 | Wear; 0 = none |
| `InverterNoiseRadius` | 2 | 0-10 | Radius of the hum heard by zombies; 0 = silent |
| `LinkRange` | 12 | 4-30 | Maximum cable distance |
| `PumpRange` | 15 | 5-30 | Radius around a water pump where its taps are supplied |
| `WirePerTiles` | 4 | 0-20 | Tiles per electric wire; 0 = free cabling |
| `StormDamage` | false | - | Storm and strong wind damage |
| `XPMultiplier` | 1.0 | 0-10 | Experience given by the mod |
| `SkillGates` | true | - | false = no level required |
| `SimulateUnloaded` | true | - | Keeps running with nobody nearby |
| `BackupStartPercent` / `BackupStopPercent` | 20 / 90 | 0-90 / 10-100 | Backup generator thresholds |

## Player option

In **Options > Mods > Live Wire**: inverter hum volume, 0-100 (0 = off). It is per player and only affects what that player hears.

## See also

[Production and Calculations](04-production-and-calculations.md) - [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md) - [Wiring](03-wiring.md) - [Multiplayer](12-multiplayer.md)
