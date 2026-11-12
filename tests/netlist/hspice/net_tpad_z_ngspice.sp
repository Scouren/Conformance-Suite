* HSPICE .NET (obsolete .LIN predecessor) on a resistive T network, both
* ngspice twin of hspice/net_tpad_z.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* ports open (.NET V(c) Iin, the Z form): R1 = 10, R2 = 100 to ground,
* R3 = 20, so Z = [[110, 100], [100, 120]]; S against RIN = 50 and
* ROUT = 75. Same network and answer as net_tpad_y.
* Oracle: analytic (see the expected.json derivation).
* Expected results: net_tpad_z_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
IIN 0 a ac 1
R1 a b 10
R2 b 0 100
R3 b c 20
.ac lin 1 1k 1k
.net v(c) iin rout=75 rin=50
.end
