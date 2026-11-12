* Source waveform class, AM: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_am.expected.json
* AM(VO VMO VMA FM FC TD PHASEM PHASEC) is 0 while t - TD <= 0
* (vsrcload.c:307-309, isrcload.c:280-282): 0 at t = 0 even with TD = 0.
* Past TD, (0.5 + sin(2 pi 200k t' + 45deg)) sin(2 pi 1meg t' + 90deg) on
* t' = t - TD, 1.207971 at t' = 1 ns. Before the fix espice gave
* va_t0 = ia_t0 = 1.207107, the waveform at t' = 0 (SpiceRack P8-060).
Va va 0 AM(0 0.5 1 200k 1meg 0 45 90)
Vb vb 0 AM(0 0.5 1 200k 1meg 250n 45 90)
Ia 0 ia AM(0 0.5 1 200k 1meg 0 45 90)
Ib 0 ib AM(0 0.5 1 200k 1meg 250n 45 90)
Rva va 0 1
Rvb vb 0 1
Ria ia 0 1
Rib ib 0 1
.tran 0.1n 260n 0 0.1n
.meas tran va_t0 find v(va) at=0
.meas tran va_td find v(va) at=1n
.meas tran vb_t0 find v(vb) at=0
.meas tran vb_td find v(vb) at=251n
.meas tran ia_t0 find v(ia) at=0
.meas tran ia_td find v(ia) at=1n
.meas tran ib_t0 find v(ib) at=0
.meas tran ib_td find v(ib) at=251n
.end
