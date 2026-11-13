* .option gshunt adds a conductance from every node to ground [CR Ch.3];
* ngspice twin of hspice/gshunt.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* ignoring it left the answer unmoved. Oracle: analytic, 1 mA into
* 1k || 1 mS = 0.5 V.
* Expected results: gshunt_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.option gshunt=1m gmin=1e-12 vntol=1e-6 reltol=1e-3 abstol=1e-12 method=gear post
i1 0 a 1m
r1 a 0 1k
.op
.end
