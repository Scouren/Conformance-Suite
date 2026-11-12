* HSPICE .ac POI np f1 ... fn [CR .AC]: an explicit frequency list.
* ngspice twin of hspice/ac_poi.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Oracle: analytic RC low-pass, H = 1/(1 + j*2*pi*f*R*C), R*C = 1 ms.
* Expected results: ac_poi_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 in 0 ac 1
r1 in out 1k
c1 out 0 1u
.ac poi 3 10 159.1549431 1k
.end
