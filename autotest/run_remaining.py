"""CXX: copied SP/MP worlds, then a real process restart to check saved state."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT.parent / '.claude' / 'tools' / 'pz-autotest'))
from pzat import core
from pzat.runner import Env, Options, Runner, client_java_command, server_java_command


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['sp', 'mp'])
    args = parser.parse_args()
    project = core.load_project(ROOT / 'autotest' / 'remaining.json')
    previous, phases, code = None, [], 0
    for phase in ['create', 'reload']:
        env = Env()
        if previous and args.mode == 'sp':
            env.zomboid = previous.procs[0].cache
        old_server = next((p.cache for p in previous.procs if p.kind == 'server'), None) if previous else None

        def server_command(env, cache, name, admin, password, xmx):
            if old_server:
                shutil.copytree(old_server / 'Saves', cache / 'Saves')
                # A dedicated server reloads sandbox settings from Server/, not
                # just the world snapshot. Keep the test's public-water shutdown.
                settings = f'{name}_SandboxVars.lua'
                shutil.copy2(old_server / 'Server' / settings, cache / 'Server' / settings)
            return server_java_command(env, cache, name, admin, password, xmx)

        def client_command(env, cache, xmx):
            command = cache / 'Lua' / core.LUA_DIR / 'command.txt'
            command.write_bytes(command.read_text(encoding='utf-8').replace('run=false', 'run=true').encode())
            if args.mode == 'mp' and phase == 'reload':
                driver = cache / 'mods' / core.DRIVER_ID / '42' / 'media' / 'lua' / 'client' / 'PZAutoTest' / 'PZAT_Client.lua'
                source = driver.read_text(encoding='utf-8')
                marker = '\nreturn C'
                if marker not in source:
                    raise RuntimeError('private driver entry point changed')
                source = source.replace(marker, '''
Events.OnConnected.Add(function()
    if not Z.hasStatus("load") then Z.status("load", "CXX saved-character reconnect") end
end)
''' + marker)
                driver.write_bytes(source.encode())
            return client_java_command(env, cache, xmx)

        env.server_command, env.client_command = server_command, client_command
        runner = Runner(project, Options(mode=args.mode, params={'phase': phase},
                        wait_idle=3600, keep_cache=True, client_run=True,
                        clients=2 if args.mode == 'mp' else None), env)
        code = runner.run()
        phases.append({'phase': phase, 'exit': code, 'results': str(runner.out)})
        if code:
            break
        if args.mode == 'mp':
            second = runner.out / 'client2' / 'result.txt'
            result = core.parse_result(second.read_text(encoding='utf-8')) if second.exists() else {}
            if result.get('ok') is not True:
                phases[-1]['exit'] = code = 1
                break
        previous = runner
    report = ROOT / 'runs' / f'remaining-{args.mode}-latest.json'
    report.write_text(json.dumps(phases, indent=2), encoding='utf-8')
    print(f'CXX campaign: {len(phases)}/2 phases, exit={code}, report={report}', flush=True)
    return code


if __name__ == '__main__':
    raise SystemExit(main())
