* HSPICE .NET one-port form (.NET Vin RIN=val): a 30 ohm resistor in series
* ngspice twin of hspice/net_one_port.sp (P1-062): the same circuit and oracle in ESPice's own dialect, with HSPICE's defaults written out.
* with 10 nF behind the input source, S11 = (Z - 50) / (Z + 50) with
* Z = 30 + 1/(j w C), at 100 kHz and 1 MHz.
* Oracle: analytic (see the expected.json derivation).
* Expected results: net_one_port_ngspice.expected.json
* HSPICE: TNOM 25 degC, and the circuit at TNOM unless the deck sets TEMP.
.options tnom=25 temp=25
VIN a 0 ac 1
R1 a b 30
C1 b 0 10n
.ac dec 1 100k 1meg
.net vin rin=50
.end
