* HSPICE .load [CR .LOAD] inlines the .ic cards a .save TYPE=IC wrote
* ngspice twin of hspice/load_ic.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* (load_ic.ic0: v(b) = 0.25 V). Oracle: analytic; with UIC the capacitor
* starts at 0.25 V and charges through 1k from 1 V: v(b) = 1 - 0.75
* exp(-t / 1 us). Without the load it would start at 0.
* Expected results: load_ic_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
v1 a 0 1
r1 a b 1k
c1 b 0 1n
.load file=load_ic.ic0
.tran 10n 5u uic
.end
