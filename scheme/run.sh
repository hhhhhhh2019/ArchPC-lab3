#!/usr/bin/env sh

set -e

perl microcode_compiler.pl microcode > microcode.vh
iverilog -o f32a_sim.vvp f32a_processor.v control_unit.v ram.v cpu_simulation.v
vvp f32a_sim.vvp
gtkwave simulation.vcd
