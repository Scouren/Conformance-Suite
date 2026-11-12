* Model parameters over temper through a .dc temp sweep: ngspice
* tests/regression/temper/temper-2.cir. d_test's is = 1e-12*temper sits
* beside d_fix's 1e-12 at the same voltage, so i(v_test)/i(v_fix) is the
* temperature (src/tests/temper.zig checks that ratio).
* Expected results: temper_dc_sweep_diode.expected.json
.model dtest D is='1e-12 * temper'
.model dfix  D is='1e-12'
v1  1 0  dc 5v
r1  1 2  5k
d_test  2 3  dtest
v_test  3 0  dc=0
d_fix   2 4  dfix
v_fix   4 0  dc=0
.dc temp 10 100 10.0
.end
