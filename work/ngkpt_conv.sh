#!/bin/bash

#convergence regarding ngkpt if prev_etotal - cur_etotal < delta_etotal_conv"
delta_etotal_conv="0.001"
#Number of points to plot after the converged point
pts_after_conv="10"

#path of input file with current value of ngkpt
temp_input_file_path="temp_input_file.in"

prev_etotal="9999999"
cur_etotal="0"
conv_etotal="0"
conv_ngkpt="0"
ngkpt="1"

has_converged="0"

ngkpt_vec=""
etotal_vec=""

conv_values_saved=false

first_iter=true

while [[ "$has_converged" == "0"|| "$pts_after_conv" > "0" ]]; do

  output_file_path="../output/bismuth_ngkpt_$ngkpt.out"

  #built abinit input, referring to temporary current .in file with one ngkpt value
  #and specifying corresponding output file
  abinit_files="$temp_input_file_path
$output_file_path
tbase1_xi
tbase1_xo
tbase1_x
../psps/LDA/83bi.pspnc"

  #add ngkpt value to reference .in file, thus building the temporary .in file
  { cat ../input/bismuth_kpt_conv.in; echo "ngkpt $ngkpt $ngkpt $ngkpt"; } > $temp_input_file_path
  #launch abinit with ngkpt value of current iteration
  log="log_ngkpt_$ngkpt"
  echo "$abinit_files" | abinit >& $log
  #delete temporary .in file
  rm $temp_input_file_path

  cur_etotal=$(awk '{for(i=1;i<=NF;i++) if ($i=="etotal") print $(i+1)}' $output_file_path)
  #From scientific notation to decimal, bc does not handle correctly scientific notation
  cur_etotal=$(python -c "print '%.16f' % float('$cur_etotal')")
  delta_etotal=$(python -c "print '%.16f' % abs(float('$prev_etotal') - float('$cur_etotal'))")
  bc_arg="$delta_etotal < $delta_etotal_conv"
  has_converged=$(bc <<< $bc_arg)

  if $first_iter;
  then
    ngkpt_vec="$ngkpt"
    etotal_vec="$cur_etotal"
    first_iter=false
  else
    ngkpt_vec="$ngkpt_vec $ngkpt"
    etotal_vec="$etotal_vec $cur_etotal"
  fi

  echo "ngkpt $ngkpt"
  echo "etotal $cur_etotal"

  prev_etotal=$cur_etotal

  if $conv_values_saved ;
  then
    ((pts_after_conv--))
  fi

  if [[ "$has_converged" == "1" && $conv_values_saved == false ]] ;
  then
    conv_ngkpt=$ngkpt
    conv_etotal=$cur_etotal
    conv_values_saved=true
  fi

  ((ngkpt++))

done

python << END

import matplotlib.pyplot as plt

ngkpt_vec = map(int, "$ngkpt_vec".split(' '))
etotal_vec= map(float, "$etotal_vec".split(' '))

print(ngkpt_vec)
print(etotal_vec)

plt.plot(ngkpt_vec, etotal_vec, 'ro')
energy_err_interval = $delta_etotal_conv*$conv_etotal
plt.plot(ngkpt_vec, [$conv_etotal+energy_err_interval/2.0]*len(ngkpt_vec))
plt.plot(ngkpt_vec, [$conv_etotal-energy_err_interval/2.0]*len(ngkpt_vec))

plt.xlabel('ngkpt')
plt.ylabel('etotal')
plt.savefig('../figures/ngkpt_conv.png')
END

echo "Converged ngkpt $conv_ngkpt"
echo "Converged etotal $conv_etotal"
