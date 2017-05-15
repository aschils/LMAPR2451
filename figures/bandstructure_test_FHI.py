from abipy.abilab import abiopen
import abipy.data as abidata


project_dir_path = "/Users/audreynsamela/Desktop/DOSSIER_UCL/Master/Q2/Atomistic_nanoscopic_simulations/ZnO_Project/"

#filename1 = abidata.ref_file(project_dir_path+"Band_Struct_FHIo_DS1_GSR.nc")

filename2 = abidata.ref_file(project_dir_path+"Band_Struct_FHIo_DS2_GSR.nc")

# Open the GSR file and extract the band structure.
# (alternatively one can use the shell and `abiopen.py OUT_GSR.nc -nb` to open the file in a jupyter notebook.
with abiopen(filename2) as ncfile:
    ebands = ncfile.ebands

# Plot the band energies. Note that the labels for the k-points
# are found automatically in an internal database.
ebands.plot(title="Zinc oxide band structure",savefig=project_dir_path+"bandstruct_test_FHI.png")

# Plot the BZ and the k-point path.
ebands.kpoints.plot()

#edos = gs_ebands.get_edos()

#nscf_ebands.plot_with_edos(edos, e0=None)

#print("nscf_ebands.efermi", nscf_ebands.fermie)
#print("gs_ebands.efermi", gs_ebands.fermie)
