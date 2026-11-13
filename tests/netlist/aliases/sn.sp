* `.sn` is refused: ESPice reads `.pss`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: sn.expected.json
Vin in 0 SIN(0 1 1k) AC 1
R1 in out 1000
C1 out 0 1e-06
.sn tres=3.90625u period=1m
.end
