# !/bin/bash

data_f_path="tsmear_conv_so.txt"
fig_f_path="tsmear_conv_from_outp_so.png"
delta_conv_acell="0.002"

tsmear_vec=$(grep "tsmear" $data_f_path)
acell_vec=$(grep "acell" $data_f_path)

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
delta_conv_acell = $delta_conv_acell
conv_acell = acell_vec[-3]
acell_err_interval = delta_conv_acell*conv_acell
plt.plot(tsmear_vec, [conv_acell+acell_err_interval/2.0]*len(tsmear_vec))
plt.plot(tsmear_vec, [conv_acell-acell_err_interval/2.0]*len(tsmear_vec))

plt.xlabel('tsmear (Ha)')
plt.ylabel('acell (Bohr)')
plt.savefig("$fig_f_path")

print("conv acell")
print(conv_acell)
print("conv tsmear")
print(tsmear_vec[-2])
END
