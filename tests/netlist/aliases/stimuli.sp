* `.stimuli` is refused: ESPice reads `.stim`, and SpiceRack writes that for any
* other spelling (the keyword rule: one spelling per capability).
* Expected results: stimuli.expected.json
v1 a 0 sin(0 1 1meg)
r1 a 0 1k
.stimuli tran pwl v(a)
.tran 1n 2u
.end
