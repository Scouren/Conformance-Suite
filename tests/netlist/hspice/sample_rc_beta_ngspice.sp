* HSPICE .sample BETA [CR .SAMPLE]: the sample_rc network (R = 1k to a
* grounded source, C = 1 nF, fc = 159.155 kHz) sampled at FS = 1 MHz
* through an integrator clocked at duty cycle BETA = 0.5. Oracle: analytic
* under ESPice's reading of BETA, an averaging window of BETA / FS seconds
* ahead of the sampler (HSPICE gives no transfer; unconfirmed):
* onoise_sampled^2 at f is the sum over k of
* S(g) sinc^2(pi g BETA / FS), g = |f + k FS|, 0 < g <= MAXFLD * FS, with
* S(g) = 4kTR / (1 + (g / fc)^2) at 25 degC.
* ngspice twin of hspice/sample_rc_beta.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Expected results: sample_rc_beta_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
vs in 0 dc 0 ac 1
r1 in out 1k
c1 out 0 1n
.noise v(out) vs dec 10 1k 1meg
.sample fs=1meg maxfld=10 beta=0.5
.end
