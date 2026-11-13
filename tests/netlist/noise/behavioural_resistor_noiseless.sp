* Behavioural resistor noise: without noisy=1 (and with ngspice's
* enable_noisy_r unset) an R that reads v() is a noiseless B source
* (inpcom.c:6869-6875), so only R1's thermal noise reaches out.
* Expected results: behavioural_resistor_noiseless.expected.json
* Oracle (analytic): output PSD = 4 kB T R1 (R2/(R1 + R2))^2 = 4 kB T 250
* at T = 300.15 K, spectrum = sqrt(PSD), input spectrum = output/0.5,
* integrated RMS = sqrt(PSD (fstop - fstart)). ngspice-45 on this deck
* agrees to 2e-7.
Vin in 0 DC 0 AC 1
R1 in out 1000
R2 out 0 '1000+0*v(out)'
.noise v(out) Vin dec 4 10 10k
.options temp=27 tnom=27
.end
