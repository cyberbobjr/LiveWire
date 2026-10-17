> Version francaise : [[Raccordement|Raccordement]]

# Wiring

Devices are linked to an inverter with electric wire. The house itself needs no wiring: any appliance within range of the inverter is powered.

## Step by step

1. Craft the devices (see [[Recipes|Recipes]]) and place them with the furniture cursor.
2. Right-click a device, then **Live Wire**, then the device name. It shows "Connected to the inverter N tiles away" or "Not connected". Then choose **Connect to an inverter**: one line per inverter in range, "Inverter N tiles away (k wires)".
3. Or right-click the inverter and choose **Connect equipment**: a list of free equipment in range with distance and number of wires. **Disconnect equipment** does the opposite.

![The Live Wire menu on the inverter](https://raw.githubusercontent.com/cyberbobjr/LiveWire/main/docs/shots/shot1.png)

## Wire cost

Electric wire `Base.ElectricWire`: **1 wire per 4 tiles of distance, rounded up, at least 1** (sandbox `WirePerTiles`; 0 = free).

| Distance | Calculation | Wires |
|---|---|---|
| 4 tiles | 4 / 4 = 1 | 1 |
| 9 tiles | 9 / 4 = 2.25, rounded up | 3 |
| 12 tiles | 12 / 4 = 3 | 3 |

## Range and limits

| Item | Value |
|---|---|
| Cable range | 12 tiles (sandbox `LinkRange`, 4-30), at most 1 floor apart |
| Inverters per network | 1 |
| Breakers per network | 1 |
| Alarms per network | 1 |
| Management computers per network | 1 |
| Backup generators per network | 1 |

## Vanilla generator and computer

The vanilla generator (backup) and the vanilla desktop computer (management) are linked the same way, from their own right-click menu: **Live Wire**, then Backup generator or Management computer, then **Connect to an inverter**.

## Picking up and rotating

- Picking up the inverter disconnects its whole network.
- Rotating the inverter keeps the links.
- Picking up a source keeps its condition; placed again, it is "Not connected".

## Inverter right-click menu

Open the inverter screen, Turn on / Turn off, Reset (after a trip), Show the powered area (a cyan circle on the ground), Connect equipment, Disconnect equipment, Soundproof the inverter, Inspect, Repair, Overhaul.

## See also

[[Equipment|Equipment]] - [[Inverter Screen and Software|Inverter-Screen-and-Software]] - [[Optional Equipment|Optional-Equipment]] - [[Sandbox Options|Sandbox-Options]]
