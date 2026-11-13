* A resistor model's r over temper through a .dc temp sweep: ngspice
* tests/regression/temper/temper-3.cir. r = 1000 + temper, so
* i(v1) = -5/(1000 + T).
* Expected results: temper_dc_sweep_resistor.expected.json
.model rtest r r='1000 + temper'
.model rfix  r r='1000'
v1  1 0  dc 5v
r_test  1 0  rtest
.dc temp 10 100 10.0
.end
