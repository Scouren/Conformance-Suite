* KNOWN GAP: TRNOISE is refused; espice has no transient noise generator (#72)
* Source waveform class, TRNOISE: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_trnoise.expected.json
* TRNOISE(NA NT NALPHA NAMP) has no TD and is 0 at t = 0, plus DC
* (vsrcload.c:391-392, 412-413). Vb has NA = 0 and stays at DC; Va's noise
* past t = 0 is random, so Va is sampled at t = 0 only.
Va va 0 dc 0.3 trnoise(0.1 1n 0 0)
Vb vb 0 dc 0.3 trnoise(0 1n 0 0)
Ia 0 ia dc 0.3 trnoise(0.1 1n 0 0)
Ib 0 ib dc 0.3 trnoise(0 1n 0 0)
Rva va 0 1
Rvb vb 0 1
Ria ia 0 1
Rib ib 0 1
.tran 0.1n 260n 0 0.1n
.meas tran va_t0 find v(va) at=0
.meas tran vb_t0 find v(vb) at=0
.meas tran vb_td find v(vb) at=251n
.meas tran ia_t0 find v(ia) at=0
.meas tran ib_t0 find v(ib) at=0
.meas tran ib_td find v(ib) at=251n
.end
