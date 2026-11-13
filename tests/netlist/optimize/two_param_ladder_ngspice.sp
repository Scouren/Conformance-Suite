* HSPICE optimization of two parameters against two goals: a three
* ngspice twin of optimize/two_param_ladder.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* resistor ladder whose taps must read 3 V and 1 V. Oracle: analytic,
* v(b) = 1 V puts 1 mA through the 1k foot, so ra = (5 - 3) / 1m = 2k and
* rb = (3 - 1) / 1m = 2k, the only solution.
* Expected results: two_param_ladder_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param ra=opt2(1k, 100, 10k) rb=opt2(1k, 100, 10k)
v1 in 0 5
r1 in a ra
r2 a b rb
r3 b 0 1k
.model optmod opt relin=1e-6
.dc v1 0 5 1 sweep optimize=opt2 results=va,vb model=optmod
.meas dc va find v(a) at=5 goal=3
.meas dc vb find v(b) at=5 goal=1
.end
