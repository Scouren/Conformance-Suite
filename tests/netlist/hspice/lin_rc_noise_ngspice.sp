* HSPICE .lin on a lossy RC two-port with unequal port impedances (50 and 75 ohm): S, Y, Z, H, group delay of every entry and the noise parameters of a passive network at 290 K.
* ngspice twin of hspice/lin_rc_noise.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Oracle: analytic (see the expected.json derivation).
* Expected results: lin_rc_noise_ngspice.expected.json
V1 p1 0 dc 0 portnum 1 z0 50
V2 p2 0 dc 0 portnum 2 z0 75
R1 p1 x 20
R2 x 0 100
C3 x p2 2e-09
R4 p2 0 200
.temp 16.85
.option tnom=16.85
.ac dec 2 1e+06 1e+08
.lin noisecalc=1 gdcalc=1
.end