* `.montecarlo` is refused: ESPice reads `.mc`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: montecarlo.expected.json
Vin in 0 10
R1 in out 1000
R2 out 0 3000
.montecarlo 4 0
.end
