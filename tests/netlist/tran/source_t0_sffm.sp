* Source waveform class, SFFM: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_sffm.expected.json
* V: SFFM(VO VA FM MDI FC TD PHASEM PHASEC) is 0 while t - TD <= 0
* (vsrcload.c:271-273), then 0.5 + sin(2 pi 1meg t' + 25deg
* + 1.5 sin(2 pi 500k t' + 40deg)), 1.487164 at t' = 1 ns.
* I: ngspice's current source has no delay and reads PHASEM from the TD
* slot and PHASEC from PHASEM's (isrcload.c:222-252): ia_t0 = 0.5 + sin(40deg).
Va va 0 SFFM(0.5 1 500k 1.5 1meg 0 40 25)
Vb vb 0 SFFM(0.5 1 500k 1.5 1meg 250n 40 25)
Ia 0 ia SFFM(0.5 1 500k 1.5 1meg 0 40 25)
Ib 0 ib SFFM(0.5 1 500k 1.5 1meg 250n 40 25)
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
