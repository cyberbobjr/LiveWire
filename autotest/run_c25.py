"""C25: real process restarts on copied SP/MP worlds, using pz-autotest.

Run from the project: python autotest/run_c25.py sp (or mp).
Only test caches are copied; the user's save and Steam Workshop remain read-only.
"""
from __future__ import annotations

import argparse
import copy
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
    project = core.load_project(ROOT / 'autotest' / 'fixes.json')
    project.conf = copy.deepcopy(project.conf)
    project.conf['name'] = 'LiveWire-C25'
    project.conf['hooks'] = 'lw_c25_hooks.lua'
    project.conf['sp']['timeoutSec'] = 360
    project.conf['mp'].update(clients=2, timeoutSec=480, joinTimeoutSec=240)
    previous = None
    phases = []
    for phase in ['create', 'reload', 'clean']:
        env = Env()
        if previous and args.mode == 'sp':
            env.zomboid = previous.procs[0].cache  # source is a stopped, private test copy
        old_server = next((p.cache for p in previous.procs if p.kind == 'server'), None) if previous else None

        def server_command(env, cache, name, admin, password, xmx):
            if old_server:
                shutil.copytree(old_server / 'Saves', cache / 'Saves')
            return server_java_command(env, cache, name, admin, password, xmx)

        def client_command(env, cache, xmx):
            # The generic runner normally enables hooks only for client 1. C25
            # explicitly waits for both observers before each server transition.
            command = cache / 'Lua' / core.LUA_DIR / 'command.txt'
            text = command.read_text(encoding='utf-8').replace('run=false', 'run=true')
            command.write_bytes(text.encode('utf-8'))
            if args.mode == 'mp' and phase != 'create':
                # The stock driver relies on OnFETick after character creation.
                # Reconnecting a saved character bypasses that screen; record the
                # native OnConnected transition in this private driver copy only.
                driver = cache / 'mods' / core.DRIVER_ID / '42' / 'media' / 'lua' / 'client' / 'PZAutoTest' / 'PZAT_Client.lua'
                source = driver.read_text(encoding='utf-8')
                marker = '\nreturn C'
                addition = '''
Events.OnConnected.Add(function()
    if not Z.hasStatus("load") then Z.status("load", "C25 saved-character reconnect") end
end)
'''
                if marker not in source:
                    raise RuntimeError('private driver entry point changed')
                driver.write_bytes(source.replace(marker, addition + marker).encode('utf-8'))
            return client_java_command(env, cache, xmx)

        env.server_command, env.client_command = server_command, client_command
        opts = Options(mode=args.mode, params={'phase': phase}, wait_idle=3600,
                       keep_cache=True, client_run=True, clients=2 if args.mode == 'mp' else None)
        runner = Runner(project, opts, env)
        code = runner.run()
        phases.append({'phase': phase, 'exit': code, 'results': str(runner.out)})
        if code:
            break
        if args.mode == 'mp':
            # Client 2 is controlled by our barrier, so also require its own result.
            second = runner.out / 'client2' / 'result.txt'
            result = core.parse_result(second.read_text(encoding='utf-8')) if second.exists() else {}
            if result.get('ok') is not True:
                phases[-1]['exit'] = code = 1
                break
        previous = runner
    report = ROOT / 'runs' / f'c25-{args.mode}-latest.json'
    report.write_text(json.dumps(phases, indent=2), encoding='utf-8')
    print(f'C25 campaign: {len(phases)}/3 phases, exit={code}, report={report}', flush=True)
    return code


if __name__ == '__main__':
    raise SystemExit(main())
