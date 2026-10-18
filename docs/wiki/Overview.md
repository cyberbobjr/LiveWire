> Version francaise : [[Presentation|Presentation]]

# Live Wire - Overview

**Live Wire** (`batman_LiveWire`) is a Project Zomboid **Build 42.21** mod, translated into English, French, German, Spanish, Portuguese (Brazil and Portugal), Russian, Chinese, Japanese and Korean. It turns the Electrical skill into a trade: solar panels, wind turbines and water wheels produce silent power, and an **inverter** placed in your house powers every appliance around it, with no fuel and no fumes. Batteries stored in a **power bank** keep the surplus for the night. The server is authoritative, so the mod is multiplayer-ready and designed for dedicated servers.

Everything in the mod is original: no code or asset comes from another mod.

![How it works: sources, inverter, house and power bank](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/diagram_en.png)

*How it works: sources, inverter, house and power bank.*

## Three roles, one network

```mermaid
flowchart LR
    S1[Solar panels 100 W] --> I
    S2[Wind turbine 400 W] --> I
    S3[Water wheel 120 W] --> I
    I[Inverter 1,500 W max] <--> B[(Power banks with batteries)]
    I --> H[Every appliance within 20 tiles and 3 floors]
```

| Role | Devices | What it does |
|---|---|---|
| Sources produce | Solar panel 100 W, wind turbine 400 W, water wheel 120 W (nominal) | Any number per inverter, each within cable range (12 tiles, 1 floor apart at most) |
| Batteries store (optional) | Car batteries or deep-cycle batteries inside a power bank | 4 batteries counted per power bank, charge efficiency 0.90. Several power banks per inverter |
| The inverter converts and distributes | Inverter | 1,500 W max (house demand), 20 W idle consumption, efficiency 0.85 to 1.0 (from the installer's level). One per network, can be placed indoors, no toxicity (it is not a game generator) |
| The house | Every powered appliance | Every appliance within 20 tiles and 3 floors up or down of the inverter is powered. No per-appliance wiring |

The 20 tiles and 3 floors come from the vanilla options `GeneratorTileRange` and `GeneratorVerticalPowerRange`. The game itself decides what is powered (a square is powered as if it were near a generator), so fridges, lights, stoves, TVs and radios work exactly as in vanilla.

## Minimal system

**One source + one inverter.** Without batteries the house runs on the current production only: for example, three panels on a sunny day run a fridge-freezer at noon, but not at night. Add a power bank with batteries to carry the load through the night.

## Fridges while you are away

Fridges and freezers keep food cold while you are away (area unloaded), as long as there is power. Checked in game: a fresh steak in a powered fridge, player 300 tiles away, 10 game hours: the steak aged 0.083 day (cold) instead of 0.417 day (warm).

Engine limit: the power state found when the area reloads counts for the whole absence.

## Running water (1.2.0)

A water pump wired to the inverter keeps the house taps supplied from water barrels standing next to it (vanilla rain collectors or Useful Barrels): sinks, showers, baths and toilets work again after the water shut-off. Details in [[Water Pump|Water-Pump]].

## Equipment at a glance

![All devices with their key figures](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/img/equipment_en.png)

*All devices with their key figures.*

## Screenshots

Outdoors: solar panels and a wind turbine with their green "connected" lights, and the backup generator.

![Outdoors](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot4.png)

Indoors: the inverter (lit screen), power bank, computer, wall alarm and breaker.

![Indoors](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot5.png)

## See also

[[Equipment|Equipment]] - [[Wiring|Wiring]] - [[Production and Calculations|Production-and-Calculations]] - [[Multiplayer and FAQ|Multiplayer-and-FAQ]]
