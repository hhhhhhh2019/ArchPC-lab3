#!/usr/bin/env python3
import json, sys

d = json.load(open(sys.argv[1]))
REG = ("$dff", "$adff", "$sdff", "$aldff", "$dlatch")

for mname, mod in d["modules"].items():
    names = {n: i["bits"] for n, i in mod["netnames"].items()
             if not n.startswith("$") and not i.get("hide_name")}

    def label(q):
        for n, bits in names.items():          # точное совпадение: весь регистр
            if bits == q:
                return n
        for n, bits in names.items():          # часть шины: A[31], mem_address[29:0]...
            for i in range(len(bits) - len(q) + 1):
                if bits[i:i+len(q)] == q:
                    hi = i + len(q) - 1
                    return f"{n}[{hi}:{i}]" if hi != i else f"{n}[{i}]"
        return None

    # 1) переименовать триггеры по имени провода на выходе Q
    for c in mod["cells"].values():
        if c["type"].startswith(REG):
            name = label(c["connections"].get("Q", []))
            if name:
                c["type"] = f'{name}  ({c["type"][1:]})'

    # 2) найти ячейки, выходы которых никуда не ведут
    used = set()
    for p in mod["ports"].values():
        if p["direction"] != "input":
            used.update(b for b in p["bits"] if isinstance(b, int))
    for c in mod["cells"].values():
        for p, bits in c["connections"].items():
            if c["port_directions"][p] == "input":
                used.update(b for b in bits if isinstance(b, int))
    for cn, c in mod["cells"].items():
        outs = [b for p, bits in c["connections"].items()
                if c["port_directions"][p] == "output"
                for b in bits if isinstance(b, int)]
        if outs and not any(b in used for b in outs):
            print(f"[{mname}] dangling: {c['type']} {cn}  src={c['attributes'].get('src')}",
                  file=sys.stderr)

json.dump(d, open(sys.argv[2], "w"))
