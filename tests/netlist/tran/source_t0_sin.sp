* Source waveform class, SIN: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_sin.expected.json
* SIN(VO VA FREQ TD THETA PHASE) holds VO + VA sin(PHASE) = 1 up to and at
* TD (vsrcload.c:189-191), then damps on t' = t - TD: 1.005381 at 1 ns.
Va va 0 SIN(0.5 1 1meg 0 1e5 30)
Vb vb 0 SIN(0.5 1 1meg 250n 1e5 30)
Ia 0 ia SIN(0.5 1 1meg 0 1e5 30)
Ib 0 ib SIN(0.5 1 1meg 250n 1e5 30)
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
