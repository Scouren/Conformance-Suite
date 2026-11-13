Spectre tran method=euler skipdc=yes starts from the ic statement (#151)
// Expected results: spectre_skipdc_euler.expected.json
// KNOWN GAP: spice2rack does not translate Spectre tran skipdc=yes from an ic statement (W0001) (Scouren/SpiceRack#24)
r1 (out 0) resistor r=1k
c1 (out 0) capacitor c=1n
ic out=0.5
t1 tran stop=3u maxstep=1n method=euler skipdc=yes errpreset=moderate
