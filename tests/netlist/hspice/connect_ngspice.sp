* .connect b c makes b and c one net [CR .CONNECT]. Oracle: analytic,
* ngspice twin of hspice/connect.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* 1 V across 1k through the joined net.
* Expected results: connect_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 b 0 1
.connect b c
r1 c 0 1k
.op
.end
