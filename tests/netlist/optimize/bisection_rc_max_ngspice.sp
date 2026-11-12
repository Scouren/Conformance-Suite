* HSPICE bisection over a transient, the timing use the manual describes:
* ngspice twin of optimize/bisection_rc_max.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* MAX v(out) passes when it exceeds its GOAL by 1 us, which holds for small
* enough R. The upper limit fails, the lower passes.
* Oracle: analytic, 1 - exp(-1 us / (R 1 nF)) = 0.5 at
* R = 1e-6 / (1e-9 ln 2) = 1442.695 ohm; the result passes, so it sits
* just below.
* Expected results: bisection_rc_max_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
.param rv=opt1(1k, 100, 10k)
v1 in 0 pwl(0 0 1p 1)
r1 in out rv
c1 out 0 1n
.model optmod opt method=bisection relin=1e-6 relout=1e-3 itropt=60
.tran 1n 1u sweep optimize=opt1 results=vmax model=optmod
.meas tran vmax max v(out) goal=0.5
.end
