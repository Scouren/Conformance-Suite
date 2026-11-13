* HSPICE W element, one RLC line (no Rs/Gd) against ngspice's TXL.
* ngspice twin of hspice/w_txl.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Expected results: w_txl_ngspice.expected.json
* Oracle: ngspice-44.2 with the W card as `Y1 a 0 b 0 ymod`, `.model ymod txl
* R=5 L=300n G=0 C=120p length=0.2`.
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
Vin in 0 DC 0 PULSE(0 1 0.2n 0.1n 0.1n 2n 10n)
Rs in a 50
W1 a 0 b 0 rlgcmodel=line n=1 l=0.2
RL b 0 100
.model line w modeltype=rlgc n=1 lo=300n co=120p ro=5
.tran 0.01n 6n
.end
