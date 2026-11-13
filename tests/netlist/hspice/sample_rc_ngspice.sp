* HSPICE .sample [CR .SAMPLE]: RC thermal noise, R = 1k to a grounded
* source and C = 1 nF
* (fc = 159.155 kHz), sampled at FS = 1 MHz with no integrator, folding
* every band up to MAXFLD * FS = 10 MHz. Oracle: analytic; onoise_sampled^2
* at f is the sum over k of S(|f + k FS|) for 0 < |f + k FS| <= 10 MHz, with
* S(g) = 4kTR / (1 + (g / fc)^2) at 25 degC; the unsampled spectrum is S(f).
* ngspice twin of hspice/sample_rc.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Expected results: sample_rc_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
vs in 0 dc 0 ac 1
r1 in out 1k
c1 out 0 1n
.noise v(out) vs dec 10 1k 1meg
.sample fs=1meg maxfld=10 beta=0
.end
