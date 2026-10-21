#!/usr/bin/env sh

set -e

yosys -p "read_verilog control_unit.v; hierarchy -top control_unit; proc; opt -full; simplemap t:\$reduce_and t:\$reduce_or; opt_clean -purge; write_json cu.json"
python3 label_regs.py cu.json cu.json
netlistsvg -o cu.svg cu.json
