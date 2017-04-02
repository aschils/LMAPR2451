#!/bin/bash

#path of input file with current value of ecut
temp_input_file_path="temp_input_file.in"


for ecut in {2..10}
do
  #built abinit input, referring to temporary current .in file with one ecut value
  #and specifying corresponding output file
  abinit_files="$temp_input_file_path
../output/bismuth$ecut.out
tbase1_xi
tbase1_xo
tbase1_x
../psps/LDA/83bi.pspnc"
  #echo "$abinit_files"
  #add ecut value to reference .in file, thus building the temporary .in file
  { cat ../input/bismuth_ecut_conv.in; echo "ecut $ecut"; } > $temp_input_file_path
  #launch abinit with ecut value of current iteration
  log="log_ecut_$ecut"
  echo "$abinit_files" | abinit >& $log
  #delete temporary .in file
  rm $temp_input_file_path
done
