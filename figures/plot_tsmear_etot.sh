# !/bin/bash


#path="../dump/tsmear_ngkpt_conv_etot.txt"
#fig_f_path="../figures/tsmear_ngkpt_conv_wrt_etot.png"

path="../dump/tsmear_ngkpt_conv_etot_so.txt"
fig_f_path="../figures/tsmear_ngkpt_conv_wrt_etot_so.png"


tsmear_vec=$(awk '/tsmear_vec:/{getline; print}' $path)
ngkpt_vec=$(awk '/ngkpt_vec:/{getline; print}' $path)
etotal_vec=$(awk '/etotal_vec:/{getline; print}' $path)

python << END

from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
import numpy as np

#remove useless first char space
tsmear_vec = "$tsmear_vec"[1:]
ngkpt_vec = "$ngkpt_vec"[1:]
etotal_vec = "$etotal_vec"[1:]

tsmear_vec = tsmear_vec.split(' ')
ngkpt_vec = ngkpt_vec.split(' ')
etotal_vec = etotal_vec.split(' ')

tsmear_vec = map(float, tsmear_vec)
ngkpt_vec = map(float, ngkpt_vec)
etotal_vec = map(float, etotal_vec)

fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
#ax.ticklabel_format(useOffset=True, style='sci', scilimits=(0,0))
ax.ticklabel_format(useOffset=False)
ax.scatter(tsmear_vec, ngkpt_vec, etotal_vec, c=tsmear_vec)

ax.set_xlabel('tsmear')
ax.set_ylabel('ngkpt')
ax.set_zlabel('etotal (Ha)')

ax.zaxis._axinfo['label']['space_factor'] = 2.8

plt.savefig("$fig_f_path")

END
