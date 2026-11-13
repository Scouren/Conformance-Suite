* Source waveform class, PULSE: V and I sources with TD = 0 and TD > 0, each
* sampled at t = 0 (the transient's operating point) and 1 ns past TD,
* against ngspice 44.2. tests/source_class.zig names one such deck per
* waveform. Line numbers are ngspice-45's (44.2 prints the same values).
* Expected results: source_t0_pulse.expected.json
* PULSE(V1 V2 TD TR TF PW PER) is V1 up to and at TD (vsrcload.c:122,
* 151-152), then rises over TR: 0.575 at 1 ns past TD. ngspice reads an
* eighth argument as a pulse count, not a phase (124-138).
Va va 0 PULSE(0.5 2 0 20n 30n 100n 250n)
Vb vb 0 PULSE(0.5 2 250n 20n 30n 100n 250n)
Ia 0 ia PULSE(0.5 2 0 20n 30n 100n 250n)
Ib 0 ib PULSE(0.5 2 250n 20n 30n 100n 250n)
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
