* KNOWN GAP: TRRANDOM is refused; espice has no random source generator (#72)
* Source waveform class, TRRANDOM: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_trrandom.expected.json
* TRRANDOM(1 TS TD RANGE OFFSET) is uniform in OFFSET +- RANGE, plus DC
* (vsrcload.c:417-423). RANGE = 0 makes it OFFSET + DC = 1 before and
* after TD.
Va va 0 dc 0.3 trrandom(1 10n 0 0 0.7)
Vb vb 0 dc 0.3 trrandom(1 10n 250n 0 0.7)
Ia 0 ia dc 0.3 trrandom(1 10n 0 0 0.7)
Ib 0 ib dc 0.3 trrandom(1 10n 250n 0 0.7)
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
