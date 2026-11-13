* Source waveform class, PWL: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_pwl.expected.json
* PWL holds its first value up to and at its first time, after td=
* (vsrcload.c:322-325). Vc and Ic start at 10 ns. ngspice's current source
* takes no td= (isrcpar.c), so there is no Ib.
Va va 0 PWL(0 0.5 20n 2 100n 1)
Vb vb 0 PWL(0 0.5 20n 2 100n 1) td=250n
Vc vc 0 PWL(10n 0.7 30n 2 100n 1)
Ia 0 ia PWL(0 0.5 20n 2 100n 1)
Ic 0 ic PWL(10n 0.7 30n 2 100n 1)
Rva va 0 1
Rvb vb 0 1
Rvc vc 0 1
Ria ia 0 1
Ric ic 0 1
.tran 0.1n 260n 0 0.1n
.meas tran va_t0 find v(va) at=0
.meas tran va_td find v(va) at=1n
.meas tran vb_t0 find v(vb) at=0
.meas tran vb_td find v(vb) at=251n
.meas tran vc_t0 find v(vc) at=0
.meas tran vc_td find v(vc) at=11n
.meas tran ia_t0 find v(ia) at=0
.meas tran ia_td find v(ia) at=1n
.meas tran ic_t0 find v(ic) at=0
.meas tran ic_td find v(ic) at=11n
.end
