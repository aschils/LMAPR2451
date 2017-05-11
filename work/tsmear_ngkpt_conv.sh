#!/bin/bash

#convergence regarding ngkpt if prev_etotal - cur_etotal < delta_conv_etotal"
#convergence regarding tsmear if abs(prev_acell_i - acell_i) < delta_conv_acell
#for all i
delta_conv_etotal="0.001"
delta_conv_acell="0.001" #should be 0.2% du acell converge


pts_after_conv="5"


#Without spin orbit coupling
#current values of ngkpt and tsmear are append to this file
#ref_in_file="../input/bismuth_tsmear_kpt_conv.in"
#potential_path="../psps/LDA/83bi.pspnc"
#tsmear_conv_fig_path="../figures/tsmear_conv.png"
#tsmear_ngkpt_conv_fig_path="../figures/tsmear_ngkpt_conv.png"

#With spin orbit coupling
ref_in_file="../input/bismuth_tsmear_kpt_conv_so.in"
potential_path="../psps/HGH/83bi.5.hgh"
tsmear_conv_fig_path="../figures/tsmear_conv_so.png"
tsmear_ngkpt_conv_fig_path="../figures/tsmear_ngkpt_conv_so.png"


#path of input file with current values of ngkpt and tsmear
temp_input_file_path="temp_input_file.in"

tsmear="0.5"
conv_tsmear="0"
conv_acell="0"
has_converged_tsmear="0" #boolean
prev_acell1="9999999"
prev_acell2="9999999"
prev_acell3="9999999"

tsmear_vec=""
acell_vec=""
ngkpt_vec=""
etotal_vec=""

first_iter_tsmear=true

conv_values_saved="0"

tsmear_gt_zero=$(bc <<< "$tsmear > 0")
while [[ "$has_converged_tsmear" == "0" || "$pts_after_conv" > "0" && "$tsmear_gt_zero" == "1" ]]; do

  echo "tsmear $tsmear"

  ngkpt="3"
  prev_etotal="9999999"
  cur_etotal="0"
  has_converged_ngkpt="0"

  first_iter_ngkpt=true

  while [ "$has_converged_ngkpt" -ne "1" ]
  do

    output_file_path="../output/bismuth_tsmear_$tsmear-ngkpt_$ngkpt.out"

    #built abinit input, referring to temporary current .in file with one ngkpt value
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
    delta_etotal=$(python -c "print '%.16f' % abs(float('$prev_etotal') - float('$cur_etotal'))")
    #Check if convergence condition achieved using bc (bash not able to perform float arithmetic)
    bc_arg="$delta_etotal < $delta_conv_etotal"
    has_converged_ngkpt=$(bc <<< $bc_arg)

    #Build vectors of data for plots
    if $first_iter_ngkpt;
    then
      ngkpt_vec="$ngkpt_vec$ngkpt"
      etotal_vec="$etotal_vec$cur_etotal"
      first_iter_ngkpt=false
    else
      ngkpt_vec="$ngkpt_vec $ngkpt"
      etotal_vec="$etotal_vec $cur_etotal"
    fi

    echo "ngktp $ngkpt"
    echo "etotal $cur_etotal"

    prev_etotal=$cur_etotal

    ((ngkpt++))
  done

  #Retrieve line of output file with components of the "acell" vector
  acell_line=$(sed -n -e '/END DATASET(S)/,$p' $output_file_path | grep " acell ")

  echo $acell_line

  #Check convergence condition for tsmear using python: tsmear has converged if for
  #each component of the vector "acell", the previous value of the component
  #differs from the current value in absolute value by less than delta_conv_acell
  python_out=$(python << END
  #Keep only vector components and turns list of strings to list of floats
acells_line = "$acell_line"
acells = acells_line.split(' ')
acells = filter(None, acells) #remove empty strings from list
acells.pop(0) #remove useless acell keyword
acells.pop(len(acells)-1) #remove useless Bohr keyword
acells = map(float, acells)

#Check convergence condition
acell1_conv = abs(float("$prev_acell1")-acells[0]) < float("$delta_conv_acell")
acell2_conv = abs(float("$prev_acell2")-acells[1]) < float("$delta_conv_acell")
acell3_conv = abs(float("$prev_acell3")-acells[2]) < float("$delta_conv_acell")
tsmear_converged = acell1_conv and acell2_conv and acell3_conv

#Output of python script: is tsmear converged?
if tsmear_converged:
  print("1")
else:
  print("0")

#Output components of acell
print(acells[0])
print(acells[1])
print(acells[2])
END)

  #Retrieve values output by python script
  has_converged_tsmear=$(echo "$python_out" | sed '1q;d')
  prev_acell1=$(echo "$python_out" | sed '2q;d')
  prev_acell2=$(echo "$python_out" | sed '3q;d')
  prev_acell3=$(echo "$python_out" | sed '4q;d')

  #Build vectors to plot acell_i versus tsmear
  if $first_iter_tsmear;
  then
    tsmear_vec="$tsmear"
    acell_vec="$prev_acell1"
    first_iter_tsmear=false
  else
    tsmear_vec="$tsmear_vec $tsmear"
    acell_vec="$acell_vec $prev_acell1"
  fi


  ngkpt_vec="$ngkpt_vec,"
  etotal_vec="$etotal_vec,"

  if [[ "$conv_values_saved" == "1" ]] ;
  then
    ((pts_after_conv--))
  fi

  if [[ "$has_converged_tsmear" == "1" && "$conv_values_saved" == "0" ]] ;
  then
    conv_tsmear=$tsmear
    conv_acell=$prev_acell1
    conv_values_saved="1"
  fi

  tsmear=$(bc <<< "$tsmear-0.015")
  tsmear_gt_zero=$(bc <<< "$tsmear > 0")
done

python << END

import matplotlib.pyplot as plt

#Plot acell_1 versus tsmear
tsmear_vec = map(float, "$tsmear_vec".split(' '))
acell_vec= map(float, "$acell_vec".split(' '))

plt.figure(1)
plt.plot(tsmear_vec, acell_vec, 'bo', tsmear_vec, acell_vec, 'k')
acell_err_interval = $delta_conv_acell*$conv_acell
plt.plot(tsmear_vec, [$conv_acell+acell_err_interval/2.0]*len(tsmear_vec))
plt.plot(tsmear_vec, [$conv_acell-acell_err_interval/2.0]*len(tsmear_vec))

plt.xlabel('tsmear (Ha)')
plt.ylabel('acell (Bohr)')
plt.savefig("$tsmear_conv_fig_path")

#Plot for each tsmear, etotal vs ngkpt
ngkpt_vec_vec = "$ngkpt_vec"[:-1]
ngkpt_vec_vec = ngkpt_vec_vec.split(",")
print("ngkpt_vec_vec")
print(ngkpt_vec_vec)
etotal_vec_vec = "$etotal_vec"[:-1]
etotal_vec_vec = etotal_vec_vec.split(",")
print("etotal_vec_vec")
print(etotal_vec_vec)

plt.figure(2)
for i in range(0, len(ngkpt_vec_vec)):
  ngkpt_vec = map(float, ngkpt_vec_vec[i].split(' '))
  etotal_vec = map(float, etotal_vec_vec[i].split(' '))
  label_str = "tsmear "+str(tsmear_vec[i])
  plt.plot(ngkpt_vec, etotal_vec, 'o', label=label_str)
  plt.plot(ngkpt_vec, etotal_vec, 'k')

plt.xlabel('ngkpt')
plt.ylabel('etotal (Ha)')
plt.legend()
plt.savefig("$tsmear_ngkpt_conv_fig_path")

END

echo "Conv acell $conv_acell"
echo "Conv tsmear $conv_tsmear"
