* HSPICE MONTE=list(...) [CR .DC]: run exactly the listed trials, a range
* ngspice twin of variants/monte_list.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* a:b expanded, parentheses optional. Each trial draws as it would in a
* MONTE=5 run (counter-based draws), so the plots are trials 2, 4, 5 and 3.
* Oracle: analytic, v(a) = 1 V whatever rv draws; only the trial set and
* the nominal run are checked.
* Expected results: monte_list_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rv=agauss(1k, 100, 1)
v1 a 0 1
r1 a 0 rv
.op sweep monte=list(2 4:5)
.op sweep monte=list 3
.end
