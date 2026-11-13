* ngspice tests/regression/misc/asrc-tc-1.sp (and examples/various/
* tmp-noise-2.sp): B sources whose unbraced expression is followed by
* tc1=, which ngspice's lexer stops at (inpptree.c:1529-1546).
* Expected results: asrc_tc_1.expected.json
* Oracle: ngspice-45 (the run recorded in the expected file). It equals the
* closed form: at .temp 127, dT = 400.15 - 300.15 = 100 K (asrcload.c:41),
* so both B outputs scale by 1 + 1e-3 * 100 = 1.1: i(v2) = 110 and
* v(3) = 110 at the operating point, 1.1 in AC.
v1  1 0  dc=100 ac=1

b2  2 0  i=v(1) tc1=0.001
v2  0 2  0

b3  3 0  v=v(1) tc1=0.001

.temp 127.0

.op
.ac dec 1 1kHz 1kHz
.end
