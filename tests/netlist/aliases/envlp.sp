* `.envlp` is refused: ESPice reads `.envelope`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: envlp.expected.json
Vin out 0 2
R1 out 0 1k
.envlp 1m 3m
.end
