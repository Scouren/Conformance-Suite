* HSPICE RF .hblin: frequency-translation S-parameters of two square-law
* ngspice twin of hspice/hblin_mixer.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* MOSFET mixers in saturation, gate on the RF port, source pumped by a 1 MHz
* LO, so gm(t) = beta (1 - 0.5 sin(w0 t)). P1 reads the input band f, P2 the
* lower sideband f0 - f (1 nF across it), P3 the upper sideband f0 + f.
* Oracle: analytic (see the expected.json derivation).
* Expected results: hblin_mixer_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
V1 rf 0 dc 2 portnum 1 z0 50
vlo lo 0 sin(0 0.5 1meg)
m1 if rf lo 0 nm w=10u l=1u
c1 if 0 1n
V2 if 0 dc 5 portnum 2 z0 50 hblin_h=1 hblin_s=-1
m2 up rf lo 0 nm w=20u l=1u
V3 up 0 dc 5 portnum 3 z0 50 hblin_h=1 hblin_s=1
.model nm nmos level=1 vto=1 kp=1e-4 lambda=0 gamma=0
.hb 1meg 4
.hblin poi 3 10k 100k 200k
.end
