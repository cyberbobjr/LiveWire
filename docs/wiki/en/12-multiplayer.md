> Version française : [Multijoueur](../fr/12-multijoueur.md)

# Multiplayer

## Server authority

Production, stock, states, failures and experience are computed by the **server**. The client displays and sends requests, which the server re-checks.

- Experience is granted only by the server.
- Shared installations follow the vanilla safehouse rules.
- The software may lag up to 10 game minutes.
- If the server pauses when empty, the installation pauses too.
- Vanilla generators are unchanged. If a generator and an inverter cover the same appliances, both pay.
- Debug tools: `-debug` in single player, admins in multiplayer.

## Breaker boards in multiplayer

- A client may place a breaker board in a fresh roofed player house; the server then judges the placement, and refuses it if the spot is not inside a closed, roofed room.
- A roofed porch, a yard or the edge of a map building is refused on every client. Those squares are map data.
- Wiring, switching and tripping of breakers are decided by the server.

## Admin actions before removing the add-on

On a server, an admin must switch every breaker back on before LiveWire Extended is removed from the mod list. Open the menu of a breaker board and choose **Admin: switch every breaker back on (before removing the mod)**. Once done, the boards stop cutting power and appliances get their normal state. **Admin: breaker boards work again** resumes the boards. See [LiveWire Extended](14-livewire-extended.md#removing-the-add-on).

## Licence

MIT (file `LICENSE` in the repository). No code or asset was taken from any other mod.

## See also

[Getting started](01-getting-started.md) - [Sandbox Options](11-sandbox-options.md) - [Equipment](02-equipment.md) - [Electrical skill and maintenance](10-electrical-skill-and-maintenance.md) - [FAQ](13-faq.md) - [LiveWire Extended](14-livewire-extended.md)
