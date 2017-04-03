#!/bin/bash

#convergence regarding ecut if prev_etotal - cur_etotal < delta_etotal_conv"
delta_etotal_conv="0.0001"

#path of input file with current value of ecut
temp_input_file_path="temp_input_file.in"

prev_etotal="9999999"
cur_etotal="0"
ecut="1"

has_converged="0"

while [ "$has_converged" -ne "1" ]
do

  output_file_path="../output/bismuth$ecut.out"

  #built abinit input, referring to temporary current .in file with one ecut value
  #and specifying corresponding output file
  abinit_files="$temp_input_file_path
$output_file_path
tbase1_xi
tbase1_xo
tbase1_x
../psps/LDA/83bi.pspnc"

  #add ecut value to reference .in file, thus building the temporary .in file
  { cat ../input/bismuth_ecut_conv.in; echo "ecut $ecut"; } > $temp_input_file_path
  #launch abinit with ecut value of current iteration
  log="log_ecut_$ecut"
  echo "$abinit_files" | abinit >& $log
  #delete temporary .in file
  rm $temp_input_file_path

  cur_etotal=$(awk '{for(i=1;i<=NF;i++) if ($i=="etotal") print $(i+1)}' $output_file_path)
  #From scientific notation to decimal, bc does not handle correctly scientific notation
  cur_etotal=$(python -c "print float('$cur_etotal')")

  bc_arg="$prev_etotal - $cur_etotal < $delta_etotal_conv"
  has_converged=$(bc <<< $bc_arg)

  echo $ecut
  echo $cur_etotal

  prev_etotal=$cur_etotal
  ((ecut++))

done