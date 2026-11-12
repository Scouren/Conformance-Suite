* Static RG transmission line: derived classification, the length the model's len=.
* An O card takes no length of its own: ngspice 44.2 refuses `O1 ... length=2`
* ("unknown parameter (length)"), and ESPice does too.
Vin in 0 1
O1 in 0 out 0 line
RL out 0 1
.model line LTRA r=1 g=1 len=2
.op
.end
