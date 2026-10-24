"""Size model for KahluaTableImpl.save(ByteBuffer), before UDP/RakNet overhead.

Reference: KahluaTableImpl.java:230-260 and GameWindow.StringUTF.save.
ASCII anchor keys make the UTF-8 byte count identical in Lua 5.1 and Kahlua.
"""
def value_bytes(value):
    if isinstance(value, bool):
        return 2  # type + boolean
    if isinstance(value, (int, float)):
        return 9  # type + double
    if isinstance(value, str):
        return 3 + len(value.encode('utf-8'))  # type + short length + UTF-8
    if isinstance(value, dict):
        return 5 + sum(value_bytes(k) + value_bytes(v) for k, v in value.items())
    raise TypeError(type(value))


def payload_bytes(bases, history=16):
    anchors = {}
    for n in range(1, bases + 1):
        anchors[f'd{n}'] = dict(x=10000, y=10000, z=0, on=True, log0=False,
                               log={i: dict(t=i * 12, on=bool(i % 2)) for i in range(1, history + 1)})
    # Packet body: UTF tag (no type byte), table-present flag, untyped table.
    return 2 + len('LiveWireAnchors') + 1 + value_bytes(anchors) - 1


if __name__ == '__main__':
    for n in [1, 10, 100, 500, 1000]:
        size = payload_bytes(n)
        # Two transitions per base per real hour (one game day of 60 min).
        print(f'{n} bases: {size} bytes/event/client, '
              f'{size * 2 * n / 3600 / 1024:.2f} KiB/s/client average (assumed 2 changes/day)')
