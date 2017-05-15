#!/usr/bin/env python2.7

import matplotlib.pyplot as plt

project_dir_path = "/Users/aschils/Documents/FYAP/FYAP21MS/Q2/atomistic_and_nanoscopic_simulation/projet/LMAPR2451/"
EIG_f_path = project_dir_path+"work/tbase1_xo2_EIG"
fig_f_path = project_dir_path+"figures/band_structure_nband_30.png"

with open(EIG_f_path) as f:
    f_content = f.readlines()

f_content = f_content[1:]
f_content = [x.strip() for x in f_content]


#first index: kpt point, second index: index of the band, element: energy of
#this band at this kpt point
bands = []

kpt_idx = -1
for l in f_content:
    words = l.split(' ')
    words = filter(None, words)

    if words[0] == "kpt#":
        bands.append([])
        kpt_idx = kpt_idx+1
    else:
        for word in words:
            bands[kpt_idx].append(word)

kpt_idx_l = range(0,kpt_idx)
nband = len(bands[0])

for band_idx in range(0,nband):
    band_energies = []
    for kpt_idx in kpt_idx_l:
        band_energies.append(bands[kpt_idx][band_idx])
    plt.plot(kpt_idx_l, band_energies)

plt.xticks([0, 31, 61, 91, 121, 151, 181, 211], ["$\Gamma$", "X", "K" , "$\Gamma$", "T", "W", "L", "$\Gamma$"])
plt.ylabel('Energy (eV)')
plt.savefig(fig_f_path)
#plt.show()
