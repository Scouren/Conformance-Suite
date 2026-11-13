* HSPICE optimization: size the bottom resistor of a divider so the
* ngspice twin of optimize/divider_goal.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* output sits at its GOAL. Oracle: analytic, 5 rx / (1k + rx) = 2 V gives
* rx = 2k/3 = 666.67 ohm exactly; the final .meas reads 2 V.
* Expected results: divider_goal_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rx=opt1(1k, 100, 10k)
v1 in 0 5
r1 in out 1k
r2 out 0 rx
.model optmod opt itropt=30
.dc v1 0 5 1 sweep optimize=opt1 results=vout model=optmod
.meas dc vout find v(out) at=5 goal=2
.end
