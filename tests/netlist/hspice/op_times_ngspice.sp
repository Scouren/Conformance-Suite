* HSPICE .op t1 t2 [CR .OP]: an operating point at each transient time.
* ngspice twin of hspice/op_times.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Oracle: analytic RC step response from 0 V, v(out) = 1 - exp(-t / 5 ns):
* 0.18127 at 1 ns and 0.63212 at 5 ns.
* Expected results: op_times_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 in 0 pulse(0 1 0 1p 1p 1 2)
r1 in out 1k
c1 out 0 5p
.tran 0.1n 10n
.op 1n 5n
.end
