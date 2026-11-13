* HSPICE S element in the time domain: the two-port of s_element.sp (same
* ngspice twin of hspice/s_element_tran.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* Touchstone file) driven by a 1 V pulse behind 50 ohm, loaded by 50 ohm.
* Expected results: s_element_tran_ngspice.expected.json
* Oracle: ngspice-44.2 on the lumped network the data were computed from
* (series 10 ohm + 5 nH between the ports, 100 ohm at port 1, 25 ohm + 2 pF
* at port 2).
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 in 0 pulse(0 1 0.1n 0.2n 0.2n 1n 10n)
rs in p1 50
s1 p1 p2 mname=smod
rl p2 0 50
.model smod s tstonefile=s_element.assets/net.s2p
.tran 1p 3n
.end
