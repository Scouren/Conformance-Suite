* HSPICE .lin through a matched lossless line (T element, z0 = 50, td = 1 ns):
* ngspice twin of hspice/lin_line.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* S21 = e^(-j w td) and a group delay of exactly td, taken by .lin gdcalc=1
* from a central difference across the line's frequency-dependent stamp.
* Oracle: analytic (see the expected.json derivation).
* Expected results: lin_line_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
V1 a 0 dc 0 portnum 1 z0 50
T1 a 0 b 0 z0=50 td=1n
V2 b 0 dc 0 portnum 2 z0 50
.ac lin 3 100meg 300meg
.lin gdcalc=1
.end
