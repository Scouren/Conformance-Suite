* HSPICE optimization whose GOAL lies outside the parameter's range:
* ngspice twin of optimize/unreachable_goal.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* 5 rx / (1k + rx) = 4.9 V needs rx = 49k, above the 10k limit. The
* optimizer must stop on the limit and say so. Oracle: analytic, rx ends
* at 10k and the output at 5 * 10k / 11k = 4.5455 V.
* Expected results: unreachable_goal_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rx=opt1(1k, 100, 10k)
v1 in 0 5
r1 in out 1k
r2 out 0 rx
.model optmod opt
.dc v1 0 5 1 sweep optimize=opt1 results=vout model=optmod
.meas dc vout find v(out) at=5 goal=4.9
.end
