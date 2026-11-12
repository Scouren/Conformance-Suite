* Behavioural resistor noise: noisy=1 gives an R that reads v() ngspice's
* thermal-noise network (inpcom.c:6880-6886), so R2 = 1000 + 0*v(out) is
* as noisy as a plain 1 kohm.
* Expected results: behavioural_resistor_noisy.expected.json
* Oracle (analytic): output PSD = 4 kB T (R1 || R2) at T = 300.15 K,
* spectrum = sqrt(PSD), input spectrum = output/0.5, integrated RMS =
* sqrt(PSD (fstop - fstart)). ngspice-45 on this deck agrees to 2e-7.
Vin in 0 DC 0 AC 1
R1 in out 1000
R2 out 0 '1000+0*v(out)' noisy=1
.noise v(out) Vin dec 4 10 10k
.options temp=27 tnom=27
.end
