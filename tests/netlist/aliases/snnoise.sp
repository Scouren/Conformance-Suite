* `.snnoise` is refused: ESPice reads `.pnoise`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: snnoise.expected.json
Vin in 0 SIN(0 1 1k) AC 1
R1 in out 1000
C1 out 0 1e-06
.pss 1k 256
.snnoise v(out) vin dec 2 10 100
.end
