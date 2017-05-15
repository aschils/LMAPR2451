#!/bin/bash

#No spin orbit coupling
#potential_path="../psps/LDA/83bi.pspnc"
#input_f_path="../input/bismuth_acell_conv.in"
#acell_conv_fig_path="../figures/acell_conv.png"
#dump_path="../dump/acell_conv.txt"

#With spin orbit coupling
potential_path="../psps/HGH/83bi.5.hgh"
input_f_path="../input/bismuth_acell_conv_so.in"
acell_conv_fig_path="../figures/acell_conv_so.png"
dump_path="../dump/acell_conv_so.txt"

#convergence regarding acell if prev_etotal - cur_etotal < delta_etotal_conv"
delta_etotal_conv="1" #Don't care about convergence, just take pts_after_conv
#points for the plot
#Number of points to plot after the converged point
pts_after_conv="50"

#path of input file with current value of acell
temp_input_file_path="temp_input_file.in"

prev_etotal="9999999"
cur_etotal="0"
conv_etotal="0"
conv_acell="0"
acell="8.5"

has_converged="0"

acell_vec=""
etotal_vec=""

conv_values_saved=false

first_iter=true

while [[ "$has_converged" == "0"|| "$pts_after_conv" > "0" ]]; do

  echo "start while"

  output_file_path="../output/bismuth_acell_$acell.out"

  echo "output file path build"


  #built abinit input, referring to temporary current .in file with one acell value
  #and specifying corresponding output file
  abinit_files="$temp_input_file_path
$output_file_path
tbase1_xi
tbase1_xo
tbase1_x
$potential_path"

  #add acell value to reference .in file, thus building the temporary .in file
  { cat $input_f_path; echo "acell $acell $acell $acell"; } > $temp_input_file_path

  #launch abinit with acell value of current iteration
  log="log_acell_$acell"
  echo "$abinit_files" | abinit >& $log

  echo "abinit launched"

  #delete temporary .in file
  rm $temp_input_file_path

  cur_etotal=$(awk '{for(i=1;i<=NF;i++) if ($i=="etotal") print $(i+1)}' $output_file_path)

  echo "awk finished"

  #From scientific notation to decimal, bc does not handle correctly scientific notation
  echo "cur etotal: $cur_etotal"
  cur_etotal=$(python -c "print float('$cur_etotal')")

  bc_arg="$prev_etotal - $cur_etotal < $delta_etotal_conv"
  has_converged=$(bc <<< $bc_arg)

  if $first_iter;
  then
    acell_vec="$acell"
    etotal_vec="$cur_etotal"
    first_iter=false
  else
    acell_vec="$acell_vec $acell"
    etotal_vec="$etotal_vec $cur_etotal"
  fi

  echo "acell $acell"
  echo "etotal $cur_etotal"

  prev_etotal=$cur_etotal

  if $conv_values_saved ;
  then
    ((pts_after_conv--))
  fi

  if [[ "$has_converged" == "1" && $conv_values_saved == false ]] ;
  then
    conv_acell=$acell
    conv_etotal=$cur_etotal
    conv_values_saved=true
  fi

  acell=$(bc <<< "$acell + 0.02")
done

echo "acell_vec:" >> $dump_path
echo "$acell_vec" >> $dump_path
echo "etotal_vec:" >> $dump_path
echo "$etotal_vec" >> $dump_path


python << END

import matplotlib.pyplot as plt

acell_vec = map(float, "$acell_vec".split(' '))
etotal_vec= map(float, "$etotal_vec".split(' '))

print(acell_vec)
print(etotal_vec)

plt.plot(acell_vec, etotal_vec, 'bo')

plt.xlabel('acell (bohr)')
plt.ylabel('etotal (Ha)')
plt.savefig("$acell_conv_fig_path")
END

#echo "Converged acell $conv_acell"
#echo "Converged etotal $conv_etotal"
