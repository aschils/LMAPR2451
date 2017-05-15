#!/usr/bin/env python2.7
"""
This example shows how to plot a band structure
using the eigenvalues stored in the GSR file produced by abinit at the end of the GS run.
"""

from abipy.abilab import abiopen
import abipy.data as abidata

project_dir_path = "/Users/aschils/Documents/FYAP/FYAP21MS/Q2/atomistic_and_nanoscopic_simulation/projet/LMAPR2451/"

# Here we use one of the GSR files shipped with abipy.
# Replace filename with the path to your GSR file or your WFK file.
filename = abidata.ref_file(project_dir_path+"work/tbase1_xo3_GSR.nc")

# Open the GSR file and extract the band structure.
# (alternatively one can use the shell and `abiopen.py OUT_GSR.nc -nb` to open the file in a jupyter notebook.
with abiopen(filename) as ncfile:
    ebands = ncfile.ebands

# kptbounds 0 0 0 # GAMMA
#           0 0.5 0.5 # X
#           0 0.6298982 0.3701018 # K
#           #0 1 0 # GAMMA
#           0 0 0 # GAMMA
#           0.5 0.5 0.5 # T
#           0.2402036 0.7597964 0.5 # W
#           0 0.5 0 # L
#           0 0  0 # Gamma point in another cell.


klabels_arg = {(0,0,0): "$Gamma$", (0,0.5,0.5): "X", (0,0.6298982,0.3701018): "K",
(0,0,0): "$Gamma$", (0.5,0.5,0.5): "T", (0.2402036,0.7597964,0.5): "W", (0,0.5,0): "L", (0,0,0): "$Gamma$"}

# Plot the band energies. Note that the labels for the k-points
# are found automatically in an internal database.
ebands.plot(title="Bismuth band structure", savefig=project_dir_path+"figures/band_structure_so.png", show=False)#, klabels=klabels_arg)

# Plot the BZ and the k-point path.
#ebands.kpoints.plot()
