* A model value and an instance area over temper, each a ternary: ngspice
* examples/various/todo-temper-3.cir. Dref takes Iin's 1 mA at v(1); D2
* (dplain) and D3 (dref, area) sit at that voltage through e2 and e3, so
* i(e2) = -1m*is(dplain)/is(dref) and i(e3) = -1m*area.
* Expected results: temper_ternary_area.expected.json
.model dplain d is={temper >= 25 ? 1e-10 : (temper+1)*1e-11}
.model dref   d is=1e-10
Iin  1 0  dc = -1mA
Dref 1 0  dref
e2   2 0 1 0 1
D2   2 0  dplain
e3   3 0 1 0 1
D3   3 0  dref area={temper >= 25 ? (temper+100)/100 : 2 }
.dc temp 0 125 1.0
.end
