* `.power` is refused: ESPice reads `.meas tran`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: power.expected.json
v1 a 0 sin(0 1 1meg)
r1 a 0 1k
.power v1 from=0 to=1u
.tran 1n 2u
.end
