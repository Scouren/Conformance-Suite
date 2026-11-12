* Source waveform class, EXP: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_exp.expected.json
* EXP(V1 V2 TD1 TAU1 TD2 TAU2) is V1 up to and at TD1 (vsrcload.c:217-218),
* and TD1 = 0 means TSTEP (204-206). Vc and Ic put TD2 = 100 ns before
* TD1 = 250 ns: ngspice holds V1 = 0.5 at 101 ns, where espice added the
* TD2 fall before the fix (0.481367).
Va va 0 EXP(0.5 2 0 50n 150n 80n)
Vb vb 0 EXP(0.5 2 250n 50n 400n 80n)
Vc vc 0 EXP(0.5 2 250n 50n 100n 80n)
Ia 0 ia EXP(0.5 2 0 50n 150n 80n)
Ib 0 ib EXP(0.5 2 250n 50n 400n 80n)
Ic 0 ic EXP(0.5 2 250n 50n 100n 80n)
Rva va 0 1
Rvb vb 0 1
Ria ia 0 1
Rib ib 0 1
Rvc vc 0 1
Ric ic 0 1
.tran 0.1n 260n 0 0.1n
.meas tran va_t0 find v(va) at=0
.meas tran va_td find v(va) at=1n
.meas tran vb_t0 find v(vb) at=0
.meas tran vb_td find v(vb) at=251n
.meas tran ia_t0 find v(ia) at=0
.meas tran ia_td find v(ia) at=1n
.meas tran ib_t0 find v(ib) at=0
.meas tran ib_td find v(ib) at=251n
.meas tran vc_t0 find v(vc) at=0
.meas tran vc_td2 find v(vc) at=101n
.meas tran vc_td find v(vc) at=251n
.meas tran ic_t0 find v(ic) at=0
.meas tran ic_td2 find v(ic) at=101n
.meas tran ic_td find v(ic) at=251n
.end
