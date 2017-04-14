# !/bin/bash

tsmear_vec=$(grep "tsmear" tsmear_conv.txt)
acell_vec=$(grep "acell" tsmear_conv.txt)

echo "$acell_vec"

python << END

import matplotlib.pyplot as plt

def get_val(line):
  sp = line.split(" ")
  return sp[1]

tsmear_vec = """$tsmear_vec"""
tsmear_vec = tsmear_vec.split('\n')[:-1]
tsmear_vec = map(get_val, tsmear_vec)
tsmear_vec = map(float, tsmear_vec)

acell_vec = """$acell_vec"""
acell_vec = acell_vec.split('\n')[:-1]
acell_vec = map(get_val, acell_vec)
acell_vec = map(float, acell_vec)

plt.plot(tsmear_vec, acell_vec, 'bo', tsmear_vec, acell_vec, 'k')
delta_conv_acell = 0.003
conv_acell = acell_vec[-2]
acell_err_interval = delta_conv_acell*conv_acell
plt.plot(tsmear_vec, [conv_acell+acell_err_interval/2.0]*len(tsmear_vec))
plt.plot(tsmear_vec, [conv_acell-acell_err_interval/2.0]*len(tsmear_vec))

plt.xlabel('tsmear (Ha)')
plt.ylabel('acell (Bohr)')
plt.savefig('tsmear_conv_from_outp.png')

print("conv acell")
print(conv_acell)
print("conv tsmear")
print(tsmear_vec[-2])
END
