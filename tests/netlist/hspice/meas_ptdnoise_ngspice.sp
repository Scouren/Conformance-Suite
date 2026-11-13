* HSPICE .measure PTDNOISE [CR .MEASURE] over hspice/ptdnoise_diode's
* ngspice twin of hspice/meas_ptdnoise.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* first card: the density 2 q Vt^2 / I(t) at t = 250 ns, I = 1.5 mA, flat
* in frequency. Oracle: analytic, 1.41015e-19 V^2/Hz.
* Expected results: meas_ptdnoise_ngspice.expected.json
* Respelled from `.sn tres=10n period=1u`, same job.
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
i1 0 d sin(1m 0.5m 1meg)
d1 d 0 dm
.model dm d is=1e-14 cjo=1p
.pss 1meg 100
.ptdnoise v(d) time=250n dec 2 1k 100k
.measure ptdnoise n10k find ptdnoise_density at=10k
.measure ptdnoise navg avg ptdnoise_density from=1k to=100k
.end
