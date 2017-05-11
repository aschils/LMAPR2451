#!/bin/bash

#Enable spin-orbit coupling
soc="1"

delta_conv_etotal_ngkpt="0.0003"
delta_conv_etotal_tsmear="0.0003"
delta_tsmear="0.005"
pts_after_conv="5"

#delta_conv_etotal="10"
#delta_tsmear="0.01"
#pts_after_conv="0"


#Without spin orbit coupling
#current values of ngkpt and tsmear are append to this file
ref_in_file="../input/bismuth_tsmear_kpt_conv.in"
potential_path="../psps/LDA/83bi.pspnc"
tsmear_conv_fig_path="../figures/tsmear_conv_etot.png"
tsmear_ngkpt_conv_fig_path="../figures/tsmear_ngkpt_conv_etot.png"
dump_path="../dump/tsmear_ngkpt_conv_etot.txt"

#With spin orbit coupling
if [[ "$soc" == "1" ]] ;
then
  echo "SOC enabled"
  ref_in_file="../input/bismuth_tsmear_kpt_conv_so.in"
  potential_path="../psps/HGH/83bi.5.hgh"
  tsmear_conv_fig_path="../figures/tsmear_conv_etot_so.png"
  tsmear_ngkpt_conv_fig_path="../figures/tsmear_ngkpt_conv_etot_so.png"
  dump_path="../dump/tsmear_ngkpt_conv_etot_so.txt"
fi

rm $dump_path
touch $dump_path

#path of input file with current values of ngkpt and tsmear
temp_input_file_path="temp_input_file.in"

tsmear="0.06"
conv_tsmear="0"
conv_etotal="0"
has_converged_tsmear="0" #boolean

tsmear_vec=""
ngkpt_vec=""
etotal_vec=""

first_iter_tsmear=true

conv_values_saved="0"

prev_etotal_tsmear="999999"
tsmear_gt_zero=$(bc <<< "$tsmear > 0")
while [[ "$has_converged_tsmear" == "0" || "$pts_after_conv" > "0" && "$tsmear_gt_zero" == "1" ]]; do

  echo "tsmear $tsmear"

  ngkpt="4"
  prev_etotal_ngkpt="9999999"
  cur_etotal="0"
  has_converged_ngkpt="0"

  while [ "$has_converged_ngkpt" -ne "1" ]
  do

    output_file_path="../output/bismuth_tsmear_$tsmear-ngkpt_$ngkpt.out"

    #build abinit input, referring to temporary current .in file with one ngkpt value
    #and specifying corresponding output file
    abinit_files="$temp_input_file_path
$output_file_path
tbase1_xi
tbase1_xo
tbase1_x
$potential_path"

    #add ngkpt value to reference .in file, thus building the temporary .in file
    { cat $ref_in_file; echo "ngkpt $ngkpt $ngkpt $ngkpt"; } > $temp_input_file_path
    #add tsmear value
    echo "tsmear $tsmear" >> $temp_input_file_path

    #launch abinit with ngkpt value of current iteration
    log="log_tsmear_$tsmear-ngkpt_$ngkpt"
    echo "$abinit_files" | abinit >& $log
    #delete temporary .in file
    rm $temp_input_file_path

    #if abinit simulation without failure, final values are available under
    #the string "END DATASET(S)" in the input file.
    cur_etotal=$(sed -n -e '/END DATASET(S)/,$p' $output_file_path | awk '{for(i=1;i<=NF;i++) if ($i=="etotal") print $(i+1)}')
    #From scientific notation to decimal, bc does not handle correctly scientific notation
    cur_etotal=$(python -c "print '%.16f' % float('$cur_etotal')")
    delta_etotal=$(python -c "print '%.16f' % abs(float('$prev_etotal_ngkpt') - float('$cur_etotal'))")
    #Check if convergence condition achieved using bc (bash not able to perform float arithmetic)
    bc_arg="$delta_etotal < $delta_conv_etotal_ngkpt"
    has_converged_ngkpt=$(bc <<< $bc_arg)

    #Build vectors of data for plots
    ngkpt_vec="$ngkpt_vec $ngkpt"
    etotal_vec="$etotal_vec $cur_etotal"
    tsmear_vec="$tsmear_vec $tsmear"

    echo "ngktp $ngkpt"
    echo "etotal $cur_etotal"

    prev_etotal_ngkpt=$cur_etotal

    ((ngkpt++))
  done

  echo "prev_etotal_tsmear: $prev_etotal_tsmear"
  echo "prev_etotal_ngkpt: $prev_etotal_ngkpt"
  delta_etotal=$(python -c "print '%.16f' % abs(float('$prev_etotal_tsmear') - float('$prev_etotal_ngkpt'))")
  echo "delta_etotal: $delta_etotal$"
  bc_arg="$delta_etotal < $delta_conv_etotal_tsmear"
  has_converged_tsmear=$(bc <<< $bc_arg)
  prev_etotal_tsmear=$prev_etotal_ngkpt

  if [[ "$conv_values_saved" == "1" ]] ;
  then
    ((pts_after_conv--))
  fi

  if [[ "$has_converged_tsmear" == "1" && "$conv_values_saved" == "0" ]] ;
  then
    conv_tsmear=$tsmear
    conv_etotal=$prev_etotal_tsmear
    conv_values_saved="1"
  fi

  #tsmear=$(bc <<< "$tsmear-$delta_tsmear")
  tsmear=$(python -c "print '%.16f' % ($tsmear*2.0/3.0)")
  tsmear_gt_zero=$(bc <<< "$tsmear > 0")
done

echo "conv_tsmear: $conv_tsmear    conv_etotal: $conv_etotal" >> $dump_path
echo "tsmear_vec:" >> $dump_path
echo "$tsmear_vec" >> $dump_path
echo "ngkpt_vec:" >> $dump_path
echo "$ngkpt_vec" >> $dump_path
echo "etotal_vec:" >> $dump_path
echo "$etotal_vec" >> $dump_path
