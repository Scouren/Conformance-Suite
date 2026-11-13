* HSPICE W element, lossless and matched: the far end is the near end delayed
* ngspice twin of hspice/w_lossless_delay.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* by td = l*sqrt(L0*C0) = 1 ns.
* Expected results: w_lossless_delay_ngspice.expected.json
* Oracle (analytic): v(a) = v(in)/2 (the line looks like 50 ohm), and
* v(b)(t) = v(a)(t - 1 ns).
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 in 0 pwl(0 0 1n 0 1.5n 1 4n 1 4.5n 0)
rs in a 50
w1 a 0 b 0 rlgcmodel=line n=1 l=0.1
rl b 0 50
.model line w modeltype=rlgc n=1 lo=500n co=200p
.tran 10p 7n
.end
