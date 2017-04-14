#!/bin/bash

#No spin orbit coupling
#input_f_path="../input/bismuth_ecut_conv.in"
#potential_path="../psps/LDA/83bi.pspnc"
#fig_path="../figures/ecut_conv.png"

#With spin orbit coupling
input_f_path="../input/bismuth_ecut_conv_so.in"
potential_path="../psps/HGH/83bi.5.hgh"
fig_path="../figures/ecut_conv_so.png"

#convergence regarding ecut if prev_etotal - cur_etotal < delta_etotal_conv"
delta_etotal_conv="0.001"
#Number of points to plot after the converged point
pts_after_conv="10"

#path of input file with current value of ecut
temp_input_file_path="temp_input_file.in"

prev_etotal="9999999"
cur_etotal="0"
conv_etotal="0"
conv_ecut="0"
ecut="1"

has_converged="0"

ecut_vec=""
etotal_vec=""

conv_values_saved=false

first_iter=true

while [[ "$has_converged" == "0"|| "$pts_after_conv" > "0" ]]; do

  output_file_path="../output/bismuth_ecut_$ecut.out"

  #built abinit input, referring to temporary current .in file with one ecut value
  #and specifying corresponding output file
  abinit_files="$temp_input_file_path
$output_file_path
tbase1_xi
tbase1_xo
tbase1_x
$potential_path"

  #add ecut value to reference .in file, thus building the temporary .in file
  { cat $input_f_path; echo "ecut $ecut"; } > $temp_input_file_path
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

  if $first_iter;
  then
    ecut_vec="$ecut"
    etotal_vec="$cur_etotal"
    first_iter=false
  else
    ecut_vec="$ecut_vec $ecut"
    etotal_vec="$etotal_vec $cur_etotal"
  fi

  echo "ecut $ecut"
  echo "etotal $cur_etotal"

  prev_etotal=$cur_etotal

  if $conv_values_saved ;
  then
    ((pts_after_conv--))
  fi

  if [[ "$has_converged" == "1" && $conv_values_saved == false ]] ;
  then
    conv_ecut=$ecut
    conv_etotal=$cur_etotal
    conv_values_saved=true
  fi

  ((ecut++))
done

python << END

import matplotlib.pyplot as plt

ecut_vec = map(int, "$ecut_vec".split(' '))
etotal_vec= map(float, "$etotal_vec".split(' '))

print(ecut_vec)
print(etotal_vec)

plt.plot(ecut_vec, etotal_vec, 'ro')
energy_err_interval = $delta_etotal_conv*$conv_etotal
plt.plot(ecut_vec, [$conv_etotal+energy_err_interval/2.0]*len(ecut_vec))
plt.plot(ecut_vec, [$conv_etotal-energy_err_interval/2.0]*len(ecut_vec))

plt.xlabel('ecut')
plt.ylabel('etotal (Ha)')
plt.savefig("$fig_path")
END

echo "Converged ecut $conv_ecut"
echo "Converged etotal $conv_etotal"
