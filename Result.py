import math

def Fixed32_to_Flt(A: str):
	B = str(bin(int(A, 16)))[2:].rjust(32, "0")
	sgn, val = None, 0
	for p, c in enumerate(B):
		if p == 0:
			sgn = int(c)
		else:
			val += (float(c) * (2 ** (-p+1)))

	return -val if sgn else val

def Flt_to_Fixed32(A: float) -> str:
	bStr = "0" if A >= 0 else "1"
	A = -A if A < 0 else A
	for i in range(31):
		if A >= (2**(-i)):
			bStr += "1"
			A -= (2**(-i))
		else:
			bStr += "0"

	return str(hex(int(bStr, 2)))[2:].rjust(8,"0")

# Testbench setting
Ang = [i for i in range(0,90,5)]
Rad = [math.radians(i) for i in Ang]
Cos = [math.cos(i) for i in Rad]

# Actual testbench result
Res = ["4113e40d", "3fc62f95", "3efdd378", "3deb1faf", "3bf9af70", "3a0cb3cf",
       "3746f059", "34a1aa40", "30ff8b6a", "2cee0939", "292c2825", "2469ca3f",
	   "204180b0", "1af2e89d", "16565ef2", "10308cab", "0b511803", "055f29a5"]

for ang, cos, res in zip(Ang, Cos, list(map(Fixed32_to_Flt, Res))):
	print(f"Angle = {ang:2d} deg | Cosine = {cos:.12f} | CORDIC = {res:.12f} | ERROR = {(abs(cos-res)/cos)*100.0:3.2f} %")

# Angle =  0 deg | Cosine = 1.000000000000 | CORDIC = 1.016839039512 | ERROR = 1.68 %                     
# Angle =  5 deg | Cosine = 0.996194698092 | CORDIC = 0.996471305378 | ERROR = 0.03 %
# Angle = 10 deg | Cosine = 0.984807753012 | CORDIC = 0.984242312610 | ERROR = 0.06 %
# Angle = 15 deg | Cosine = 0.965925826289 | CORDIC = 0.967475815676 | ERROR = 0.16 %
# Angle = 20 deg | Cosine = 0.939692620786 | CORDIC = 0.937114581466 | ERROR = 0.27 %
# Angle = 25 deg | Cosine = 0.906307787037 | CORDIC = 0.907025291584 | ERROR = 0.08 %
# Angle = 30 deg | Cosine = 0.866025403784 | CORDIC = 0.863704764284 | ERROR = 0.27 %
# Angle = 35 deg | Cosine = 0.819152044289 | CORDIC = 0.822367250919 | ERROR = 0.39 %
# Angle = 40 deg | Cosine = 0.766044443119 | CORDIC = 0.765597203746 | ERROR = 0.06 %
# Angle = 45 deg | Cosine = 0.707106781187 | CORDIC = 0.702028566040 | ERROR = 0.72 %
# Angle = 50 deg | Cosine = 0.642787609687 | CORDIC = 0.643320118077 | ERROR = 0.08 %
# Angle = 55 deg | Cosine = 0.573576436351 | CORDIC = 0.568956910633 | ERROR = 0.81 %
# Angle = 60 deg | Cosine = 0.500000000000 | CORDIC = 0.503997966647 | ERROR = 0.80 %
# Angle = 65 deg | Cosine = 0.422618261741 | CORDIC = 0.421075967140 | ERROR = 0.36 %
# Angle = 70 deg | Cosine = 0.342020143326 | CORDIC = 0.349021660164 | ERROR = 2.05 %
# Angle = 75 deg | Cosine = 0.258819045103 | CORDIC = 0.252963225357 | ERROR = 2.26 %
# Angle = 80 deg | Cosine = 0.173648177667 | CORDIC = 0.176824572496 | ERROR = 1.83 %
# Angle = 85 deg | Cosine = 0.087155742748 | CORDIC = 0.083933268674 | ERROR = 3.70 %