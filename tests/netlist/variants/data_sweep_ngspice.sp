* HSPICE .data table swept two ways: `.dc DATA=` solves the rows as one DC
* ngspice twin of variants/data_sweep.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* sweep (warm-started structural lanes), `SWEEP DATA=` reruns the `.ac`
* card per row. Column rl is a .param, v1 a source.
* Oracle: analytic. DC: v(b) = v1*rl/(1k+rl). AC (1 V drive, the RC low
* pass r1-c1 loaded by rl): H = rl/(rl + 1k + j w 1k rl c).
* Expected results: data_sweep_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rl=1k
v1 a 0 dc 1 ac 1
r1 a b 1k
r2 b 0 rl
c1 b 0 1n
.data rows rl v1
+ 1k 1
+ 3k 2
+ 9k 0.5
.enddata
.dc data=rows
.ac lin 3 100k 300k sweep data=rows
.end
