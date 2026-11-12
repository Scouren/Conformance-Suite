* HSPICE .acphasenoise [CR .ACPHASENOISE; RF Ch.7]: a phase-domain
* ngspice twin of phasenoise/acphasenoise_rc.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* circuit, where node voltages stand for phases in radians. The reference
* phase noise is a 1k resistor's 4kTR (rad^2/Hz) into a 1 nF loop-filter
* pole at fc = 159.155 kHz. Oracle: analytic; the output phase PSD is
* S(f) = 4kTR / (1 + (f/fc)^2) at 25 degC with ESPice's k = 1.38064852e-23
* (ngspice CONSTboltz, deliberately), and PHNOISE is the
* single-sideband L(f) = S(f)/2 in dBc/Hz (the IEEE 1139 reading; the
* manual gives no formula, unconfirmed).
* Expected results: acphasenoise_rc_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
vref in 0 dc 0 ac 1
r1 in out 1k
c1 out 0 1n
.ac dec 1 1k 1meg
.acphasenoise v(out) vref carrier=1g
.end
