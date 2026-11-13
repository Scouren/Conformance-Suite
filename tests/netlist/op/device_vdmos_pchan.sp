* A P-channel VDMOS (`pchan`) runs as vdmos.va's ty = -1, as ngspice's
* VDMOS model reads the flag (vdmosmpar.c); it was refused (#75) before
* the .va had a polarity. Expected results: device_vdmos_pchan.expected.json
* Oracle (by hand): vgs = -5, vto = -1, vds = -5 is saturation, so
* Id = kp/2 (vgs - vto)^2 = 0.5 * 16 = 8 A out of the drain source.
VD d 0 -5
VG g 0 -5
M1 d g 0 vm
.model vm vdmos pchan vto=-1 kp=1
.op
.end
