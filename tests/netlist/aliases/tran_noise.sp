* `.tran_noise` is refused: ESPice reads `.trannoise`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: tran_noise.expected.json
Vin out 0 2
R1 out 0 1k
.tran_noise 1u 10u
.end
