"""Offline tests of LW_Physics.lua with an embedded Lua 5.1 (pip install lupa).

Run: python3 -I tests/test_physics.py
These tests only cover pure formulas; nothing here proves in-game behaviour.
"""
import math
import os
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHARED = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21",
                      "media", "lua", "shared", "LiveWire")


def runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("function isClient() return false end")
    for name in ("LW_Core.lua", "LW_Defs.lua", "LW_Physics.lua"):
        with open(os.path.join(SHARED, name), encoding="ascii") as f:
            lua.execute(f.read())
    return lua


FAILS = []


def check(cond, msg):
    if not cond:
        FAILS.append(msg)
        print("FAIL:", msg)


def approx(a, b, tol=1e-6):
    return abs(a - b) <= tol * max(1.0, abs(b))


def main():
    lua = runtime()
    P = lua.globals().LiveWire.Physics

    # Solar curve and its closed-form mean.
    check(P.solarCurve(12.5, 5.1, 19.9) > 0.99, "solar peak near noon")
    check(P.solarCurve(3, 5, 20) == 0, "no sun before dawn")
    n = 2000
    num = sum(P.solarCurve(10 + (i + 0.5) * (2 / n), 6, 20) for i in range(n)) / n
    check(approx(P.solarCurveMean(10, 12, 6, 20), num, 1e-4), "solar mean matches numeric")
    day = P.solarCurveMean(0, 24, 5.1, 19.9) * 24
    check(approx(day, 2 / math.pi * 14.8, 1e-6), "daily integral = 2/pi * daylight")
    check(P.solarCurveMean(20, 22, 6, 19) == 0, "no sun after dusk")

    # Daily energy of one 100 W panel in summer: about 0.94 kWh (docs, 3.2).
    kwh = 100 * 2 / math.pi * 14.8 / 1000
    check(0.93 < kwh < 0.95, "summer panel energy order of magnitude")

    # Wind.
    check(P.windFactor(5) == 0, "below cut-in")
    check(approx(P.windFactor(25), (15 / 35) ** 3), "cubic ramp")
    check(P.windFactor(60) == 1, "rated plateau")
    check(P.windFactor(90) == 0, "storm cut-out")
    check(approx(P.windAtHeight(20, 2), 26), "height bonus")
    check(approx(P.windAtHeight(20, 9), 29), "height bonus capped at 3 floors")

    # Smoothing: one third of the gap per 10 minute step.
    s = P.smooth(100, 20, 1 / 6, 0.5)
    check(approx(s, 100 - 80 / 3), "smoothing step")
    check(P.smooth(None, 42, 1 / 6, 0.5) == 42, "smoothing starts at raw")

    # Batteries.
    check(approx(P.batteryCapacity(0.6, 100, 1), 0.6), "full capacity at 100")
    check(approx(P.batteryCapacity(0.6, 50, 1), 0.42), "capacity at 50")
    check(P.batteryCapacity(0.6, 0, 1) == 0, "dead battery")
    check(approx(P.batteryWear(0.6, 0.6, 150, False, 1), 100 / 150), "one cycle wear")
    check(approx(P.batteryWear(0.3, 0.6, 150, True, 1), 100 / 150), "deep discharge doubles")

    def step(**kw):
        bats = kw.pop("batteries", [])
        t = lua.table_from({k: v for k, v in kw.items()})
        t.batteries = lua.table_from([lua.table_from(b) for b in bats])
        r = P.stepGrid(t)
        out = {k: r[k] for k in ("on", "tripped", "servedW", "drawnKWh",
                                 "chargedKWh", "lostKWh", "stockKWh", "capacityKWh")}
        out["charges"] = [t.batteries[i + 1].charge for i in range(len(bats))]
        return out

    base = dict(idleW=20, maxW=1500, eff=0.9, dt=1 / 6, state="on")

    # Source + inverter, no battery: enough sun -> on, not enough -> off.
    r = step(productionW=300, demandW=150, wasOn=False, **base)
    check(r["on"], "no battery, enough production -> on")
    r = step(productionW=100, demandW=150, wasOn=True, **base)
    check(not r["on"], "no battery, too little production -> off")

    # Night on a battery: drain = demand / eff * dt.
    r = step(productionW=0, demandW=150, wasOn=True,
             batteries=[{"charge": 0.6, "capacity": 0.6}], **base)
    expected = (150 + 20) / 0.9 * (1 / 6) / 1000
    check(r["on"] and approx(r["drawnKWh"], expected), "night drain from battery")
    check(approx(r["charges"][0], 0.6 - expected), "battery charge updated")

    # Drain split proportionally to charge.
    r = step(productionW=0, demandW=880, wasOn=True,
             batteries=[{"charge": 0.3, "capacity": 0.6}, {"charge": 0.1, "capacity": 0.4}],
             **base)
    d1, d2 = 0.3 - r["charges"][0], 0.1 - r["charges"][1]
    check(approx(d1 / d2, 3.0, 1e-6), "proportional drain")

    # Empty battery -> off, but production still charges it.
    r = step(productionW=50, demandW=150, wasOn=True,
             batteries=[{"charge": 0.0, "capacity": 0.6}], **base)
    check(not r["on"], "empty battery and low sun -> off")
    check(approx(r["chargedKWh"], 50 * 0.9 * (1 / 6) / 1000), "house off still charges")

    # Restart needs 2% stock when production alone is too low.
    r = step(productionW=0, demandW=100, wasOn=False,
             batteries=[{"charge": 0.005, "capacity": 0.6}], **base)
    check(not r["on"], "below restart threshold stays off")
    r = step(productionW=0, demandW=100, wasOn=False,
             batteries=[{"charge": 0.05, "capacity": 0.6}], **base)
    check(r["on"], "above restart threshold restarts")

    # Overload trips.
    r = step(productionW=3000, demandW=1800, wasOn=True, **base)
    check(r["tripped"] and not r["on"], "overload trips")

    # Full battery: surplus is lost.
    r = step(productionW=1000, demandW=0, wasOn=True,
             batteries=[{"charge": 0.6, "capacity": 0.6}], **base)
    check(r["lostKWh"] > 0 and approx(r["charges"][0], 0.6), "full battery loses surplus")

    # Energy conservation in a mixed step.
    r = step(productionW=400, demandW=100, wasOn=True,
             batteries=[{"charge": 0.2, "capacity": 0.6}], **base)
    surplus_w = 400 - (100 + 20) / 0.9
    check(approx(r["chargedKWh"] + r["lostKWh"], surplus_w * 0.9 * (1 / 6) / 1000),
          "charge accounting")

    # Off state: nothing served, production charges.
    off = dict(base, state="off")
    r = step(productionW=400, demandW=100, wasOn=True,
             batteries=[{"charge": 0.2, "capacity": 0.6}], **off)
    check(not r["on"] and r["chargedKWh"] > 0, "inverter off still charges")

    # Broken inverter: no service, no charging, production lost.
    broken = dict(base, state="broken")
    r = step(productionW=400, demandW=100, wasOn=True,
             batteries=[{"charge": 0.2, "capacity": 0.6}], **broken)
    check(not r["on"] and r["chargedKWh"] == 0 and r["lostKWh"] > 0, "broken inverter")

    print("OK" if not FAILS else "%d failure(s)" % len(FAILS))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
