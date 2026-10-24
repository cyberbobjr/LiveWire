"""Offline static checks of the Live Wire mod (no game needed).

Run: python3 -I tools/check_mod.py [path/to/pz-source-42.21]
Checks:
  1. every .lua file is ASCII and compiles as Lua 5.1 (Kahlua is close to 5.1);
  2. all files load in order in a permissive stub environment (catches load-time
     errors such as calling a missing table);
  3. every translation key used in Lua/scripts exists in EN and FR, EN and FR have
     the same keys, and lone '%' signs are flagged; every other language has the
     same files, keys, %N arguments and %% signs as EN;
  4. every file in lua/server starts with the isClient() guard;
  5. models referenced by item scripts exist, and their mesh/texture files exist;
  6. event names used with Events.X.Add exist in LuaEventManager.java (if the
     reference sources are available).
Passing these checks proves nothing about in-game behaviour.
"""
import glob
import json
import os
import re
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media")
LUA = os.path.join(MEDIA, "lua")
FAILS = []


def fail(msg):
    FAILS.append(msg)
    print("FAIL:", msg)


def lua_files():
    files = []
    for side in ("shared", "client", "server"):
        for p in glob.glob(os.path.join(LUA, side, "**", "*.lua"), recursive=True):
            files.append(p)
    return files


def load_order():
    # Game order: shared, client, server; inside each, lower-case relative path.
    out = []
    for side in ("shared", "client", "server"):
        part = glob.glob(os.path.join(LUA, side, "**", "*.lua"), recursive=True)
        part.sort(key=lambda p: os.path.relpath(p, os.path.join(LUA, side)).lower())
        out += part
    return out


STUBS = r"""
local Stub = {}
local mt = {}
mt.__index = function(t, k) return Stub end
mt.__call = function(...) return Stub end
mt.__newindex = function(t, k, v) rawset(t, k, v) end
setmetatable(Stub, mt)
Events = setmetatable({}, { __index = function(t, k)
    local e = { handlers = {} }
    function e.Add(fn) table.insert(e.handlers, fn) end
    function e.Remove(fn) end
    rawset(t, k, e)
    return e
end })
function isClient() return SIDE_CLIENT end
function isServer() return SIDE_SERVER end
function require() end
ISBaseTimedAction = { derive = function(self, name) local c = { Type = name }; return c end,
                      new = function(self, ch) return { character = ch } end }
ISCollapsableWindow = { derive = function(self, name) local c = { Type = name }; return c end }
setmetatable(_G, { __index = function(t, k)
    if k == "LiveWire" or string.sub(k, 1, 2) == "LW" then return nil end
    return Stub
end })
"""


def check_lua():
    for p in lua_files():
        rel = os.path.relpath(p, ROOT)
        raw = open(p, "rb").read()
        try:
            raw.decode("ascii")
        except UnicodeDecodeError:
            fail("%s: non-ASCII bytes (Kahlua turns them into U+FFFD)" % rel)
        lua = lua51.LuaRuntime()
        f = lua.eval("function(src, name) local f, err = loadstring(src, name); return err end")
        err = f(raw.decode("latin-1"), rel)
        if err:
            fail("%s: syntax: %s" % (rel, err))
        if os.sep + "server" + os.sep in p:
            first = [l for l in raw.decode("latin-1").splitlines()
                     if l.strip() and not l.strip().startswith("--")]
            if not first or first[0].strip() != "if isClient() then return end":
                fail("%s: missing 'if isClient() then return end' guard" % rel)


def check_load(side_client, side_server, label):
    lua = lua51.LuaRuntime()
    lua.execute("SIDE_CLIENT = %s; SIDE_SERVER = %s" % (
        "true" if side_client else "false", "true" if side_server else "false"))
    lua.execute(STUBS)
    loader = lua.eval("function(src, name) local f, err = loadstring(src, name); "
                      "if not f then return err end; local ok, e = pcall(f); "
                      "if not ok then return tostring(e) end; return nil end")
    for p in load_order():
        rel = os.path.relpath(p, ROOT)
        err = loader(open(p, encoding="ascii").read(), rel)
        if err:
            fail("[%s] %s: load error: %s" % (label, rel, err))
    g = lua.globals()
    for name in ("LWLinkAction", "LWRepairAction",
                 "LWInspectAction", "LWClearSnowAction", "LWMeasureAction", "LWReconditionAction", "LWMuffleAction"):
        v = g[name]
        if v is None or lua.eval("type")(v) != "table" or v["complete"] is None:
            fail("[%s] timed action %s not defined with complete()" % (label, name))


KEY_RE = re.compile(r'"((?:IGUI|Tooltip|ContextMenu|Sandbox)_LW[A-Za-z_]*|IGUI_LW_[A-Za-z_]+)"')


def check_translations():
    used = set()
    dyn_prefixes = set()
    for p in lua_files():
        src = open(p, encoding="ascii").read()
        for m in re.finditer(r'"((?:IGUI|Tooltip|ContextMenu)_LW_[A-Za-z_]*)"', src):
            k = m.group(1)
            if k.endswith("_"):
                dyn_prefixes.add(k)
            else:
                used.add(k)
    for p in glob.glob(os.path.join(MEDIA, "scripts", "*.txt")):
        for m in re.finditer(r"Tooltip\s*=\s*(Tooltip_LW_\w+)", open(p).read()):
            used.add(m.group(1))
    tr = {}
    for lang in ("EN", "FR"):
        keys = {}
        for p in glob.glob(os.path.join(LUA, "shared", "Translate", lang, "*.json")):
            data = json.load(open(p, encoding="utf-8"))
            for k, v in data.items():
                keys[k] = v
                for bad in re.finditer(r"%(?![0-9%])", v.replace("%%", "")):
                    fail("%s %s: lone %% sign" % (lang, k))
        tr[lang] = keys
    for k in sorted(used):
        for lang in ("EN", "FR"):
            if k not in tr[lang]:
                fail("missing %s translation: %s" % (lang, k))
    for prefix in sorted(dyn_prefixes):
        for lang in ("EN", "FR"):
            if not any(k.startswith(prefix) for k in tr[lang]):
                fail("no %s translation with prefix %s" % (lang, prefix))
    if set(tr["EN"]) != set(tr["FR"]):
        for k in sorted(set(tr["EN"]) ^ set(tr["FR"])):
            fail("key only in one language: %s" % k)
    # Other languages: same files and keys as EN, same %N arguments and %% signs.
    en_files = sorted(os.path.basename(p) for p in glob.glob(os.path.join(LUA, "shared", "Translate", "EN", "*.json")))
    for d in sorted(glob.glob(os.path.join(LUA, "shared", "Translate", "*"))):
        lang = os.path.basename(d)
        if lang in ("EN", "FR"):
            continue
        files = sorted(os.path.basename(p) for p in glob.glob(os.path.join(d, "*.json")))
        if files != en_files:
            fail("%s: files differ from EN: %s" % (lang, sorted(set(files) ^ set(en_files))))
        keys = {}
        for p in glob.glob(os.path.join(d, "*.json")):
            raw = open(p, "rb").read()
            if raw.startswith(b"\xef\xbb\xbf"):
                fail("%s %s: UTF-8 BOM" % (lang, os.path.basename(p)))
            keys.update(json.loads(raw.decode("utf-8-sig")))
        for k in sorted(set(keys) ^ set(tr["EN"])):
            fail("%s: key %s %s" % (lang, k, "missing" if k in tr["EN"] else "unknown"))
        for k, v in keys.items():
            en = tr["EN"].get(k)
            if en is None:
                continue
            if sorted(re.findall(r"%[0-9]", v)) != sorted(re.findall(r"%[0-9]", en)) or v.count("%%") != en.count("%%"):
                fail("%s %s: arguments differ from EN" % (lang, k))
            if re.search(r"%(?![0-9%])", v.replace("%%", "")):
                fail("%s %s: lone %% sign" % (lang, k))
            if "�" in v or re.search(r"\w\?\w|\?{3,}", v):
                fail("%s %s: lost characters" % (lang, k))
    # Every device model and state used by the code has a label.
    defs = open(os.path.join(LUA, "shared", "LiveWire", "LW_Defs.lua")).read()
    block = defs[defs.index("Defs.devices = {"):defs.index("Defs.batteries")]
    for model in re.findall(r"^    (\w+) = \{", block, re.M):
        for lang in ("EN", "FR"):
            if "IGUI_LW_Model_" + model not in tr[lang]:
                fail("missing %s label IGUI_LW_Model_%s" % (lang, model))
    for state in ("on", "off", "tripped", "broken", "idle"):
        for lang in ("EN", "FR"):
            if "IGUI_LW_State_" + state not in tr[lang]:
                fail("missing %s label IGUI_LW_State_%s" % (lang, state))
    # Items and recipes.
    items = re.findall(r"^\s*item (\w+)\s*$", open(os.path.join(MEDIA, "scripts", "LiveWire_items.txt")).read(), re.M)
    recipes = re.findall(r"^\s*craftRecipe (\w+)\s*$", open(os.path.join(MEDIA, "scripts", "LiveWire_recipes.txt")).read(), re.M)
    for lang in ("EN", "FR"):
        for it in items:
            if "LiveWire." + it not in tr[lang]:
                fail("missing %s item name LiveWire.%s" % (lang, it))
        for r in recipes:
            if r not in tr[lang]:
                fail("missing %s recipe name %s" % (lang, r))
    # Sandbox options.
    so = open(os.path.join(MEDIA, "sandbox-options.txt")).read()
    for opt, tkey in re.findall(r"option LiveWire\.(\w+).*?translation = (\w+)", so, re.S):
        for lang in ("EN", "FR"):
            for k in ("Sandbox_" + tkey, "Sandbox_" + tkey + "_tooltip"):
                if k not in tr[lang]:
                    fail("missing %s sandbox key %s" % (lang, k))


def check_models():
    scripts = open(os.path.join(MEDIA, "scripts", "LiveWire_items.txt")).read()
    models_txt = open(os.path.join(MEDIA, "scripts", "LiveWire_models.txt")).read()
    models = dict(re.findall(r"model (\w+)\s*\{(.*?)\}", models_txt, re.S))
    for ref in re.findall(r"WorldStaticModel = LiveWire\.(\w+)", scripts):
        if ref not in models:
            fail("item references missing model LiveWire.%s" % ref)
    for name, body in models.items():
        mesh = re.search(r"mesh = ([\w/]+)", body).group(1)
        tex = re.search(r"texture = ([\w/]+)", body).group(1)
        if not os.path.exists(os.path.join(MEDIA, "models_X", mesh + ".glb")):
            fail("model %s: mesh file %s.glb missing" % (name, mesh))
        if not os.path.exists(os.path.join(MEDIA, "textures", tex + ".png")):
            fail("model %s: texture %s.png missing" % (name, tex))


def check_sound_scripts():
    # GameSoundScript.LoadClip reads distanceMin / distanceMax with Integer.parseInt:
    # a decimal value is a script load error (fatal for the world in debug mode).
    for p in glob.glob(os.path.join(MEDIA, "scripts", "*.txt")):
        for n, line in enumerate(open(p, encoding="ascii"), 1):
            m = re.match(r"\s*(distanceMin|distanceMax)\s*=\s*([^,\s]+)", line)
            if m and not re.fullmatch(r"-?\d+", m.group(2)):
                fail("%s:%d: %s must be an integer (got %s)" % (os.path.basename(p), n, m.group(1), m.group(2)))


def check_events(pz):
    path = os.path.join(pz, "java", "zombie", "Lua", "LuaEventManager.java")
    if not os.path.exists(path):
        print("skip: event check (reference sources not found)")
        return
    known = set(re.findall(r'"(\w+)"', open(path, encoding="utf-8", errors="replace").read()))
    for p in lua_files():
        for ev in re.findall(r"Events\.(\w+)\.Add", open(p, encoding="ascii").read()):
            if ev not in known:
                fail("%s: unknown event %s" % (os.path.relpath(p, ROOT), ev))


def check_versions():
    """The Lua runtime and both shipped mods must announce the same release."""
    core_path = os.path.join(LUA, "shared", "LiveWire", "LW_Core.lua")
    with open(core_path, encoding="ascii") as stream:
        match = re.search(r'LiveWire\.VERSION\s*=\s*"([^"]+)"', stream.read())
    if not match:
        fail("LW_Core.lua: missing literal LiveWire.VERSION")
        return
    version = match.group(1)
    infos = glob.glob(os.path.join(ROOT, "Contents", "mods", "*", "42.21", "mod.info"))
    for path in infos:
        with open(path, encoding="utf-8-sig") as stream:
            match = re.search(r'^modversion\s*=\s*(\S+)\s*$', stream.read(), re.MULTILINE)
        if not match or match.group(1) != version:
            fail("%s: modversion must match LiveWire.VERSION (%s)" % (os.path.relpath(path, ROOT), version))


def main():
    pz = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(ROOT), "pz-source-42.21")
    check_lua()
    check_load(False, False, "single player")
    check_load(True, False, "MP client")
    check_load(False, True, "dedicated server")
    check_translations()
    check_models()
    check_sound_scripts()
    check_events(pz)
    check_versions()
    print("OK" if not FAILS else "%d problem(s)" % len(FAILS))
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
