#!/bin/bash

#Enable spin-orbit coupling
soc="1"

#No spin orbit coupling
input_f_path="../input/bismuth_ecut_conv_reg_acell.in"
potential_path="../psps/LDA/83bi.pspnc"
fig_path="../figures/ecut_conv_reg_acell.png"
dump_path="../dump/ecut_conv_reg_acell.txt"

#With spin orbit coupling
if [[ "$soc" == "1" ]] ;
then
  echo "SOC is enabled"
  potential_path="../psps/HGH/83bi.5.hgh"
  fig_path="../figures/ecut_conv_reg_acell_so.png"
  dump_path="../dump/ecut_conv_reg_acell_so.txt"
fi

touch $dump_path

#convergence regarding ecut if prev_acell - cur_acell < delta_conv_acell"
delta_conv_acell="0.001"
#Number of points to plot after the converged point
pts_after_conv="10"

#path of input file with current value of ecut
temp_input_file_path="temp_input_file.in"

prev_acell1="9999999"
prev_acell2="9999999"
prev_acell3="9999999"
conv_acell="0"
conv_ecut="0"
ecut="1"

has_converged="0"

ecut_vec=""
acell_vec=""

conv_values_saved=false

first_iter=true

while [[ "$has_converged" == "0"|| "$pts_after_conv" > "0" ]]; do

  output_file_path="../output/bismuth_reg_acell_ecut_$ecut.out"

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

  #add SOC parameters if enabled
  if [[ "$soc" == "1" ]] ;
  then
    soc_params="nspinor 2
    nspden 1 #no spin magnetisation
    nsppol 1 #no colinear
    so_psp 2 #treat spin-orbit in the HGH form
    "
    echo "$soc_params" >> $temp_input_file_path
  fi

  #launch abinit with ecut value of current iteration
  log="log_ecut_$ecut"
  echo "$abinit_files" | abinit >& $log
  #delete temporary .in file
  rm $temp_input_file_path

  #Retrieve line of output file with components of the "acell" vector
  acell_line=$(sed -n -e '/END DATASET(S)/,$p' $output_file_path | grep " acell ")

  #Check convergence condition for ecut using python: ecut has converged if for
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
ecut_converged = acell1_conv and acell2_conv and acell3_conv

#Output of python script: is tsmear converged?
if ecut_converged:
  print("1")
else:
  print("0")

#Output components of acell
print(acells[0])
print(acells[1])
print(acells[2])
END)

  #Retrieve values output by python script
  has_converged=$(echo "$python_out" | sed '1q;d')
  prev_acell1=$(echo "$python_out" | sed '2q;d')
  prev_acell2=$(echo "$python_out" | sed '3q;d')
  prev_acell3=$(echo "$python_out" | sed '4q;d')

  if $first_iter;
  then
    ecut_vec="$ecut"
    acell_vec="$prev_acell1"
    first_iter=false
  else
    ecut_vec="$ecut_vec $ecut"
    acell_vec="$acell_vec $prev_acell1"
  fi

  echo "ecut $ecut"
  echo "acell $prev_acell1"

  if $conv_values_saved ;
  then
    ((pts_after_conv--))
  fi

  if [[ "$has_converged" == "1" && $conv_values_saved == false ]] ;
  then
    conv_ecut=$ecut
    conv_acell=$prev_acell1
    conv_values_saved=true
  fi

  ((ecut++))
done

echo "conv_acell: $conv_acell (Bohr)  conv_ecut: $conv_ecut  (Ha)" >> $dump_path
echo "ecut_vec:" >> $dump_path
echo "$ecut_vec" >> $dump_path
echo "acell_vec:" >> $dump_path
echo "$acell_vec" >> $dump_path

python << END

import matplotlib.pyplot as plt

ecut_vec = map(int, "$ecut_vec".split(' '))
acell_vec= map(float, "$acell_vec".split(' '))

print(ecut_vec)
print(acell_vec)

plt.plot(ecut_vec, acell_vec, 'ro')
energy_err_interval = $delta_conv_acell*$conv_acell
plt.plot(ecut_vec, [$conv_acell+energy_err_interval/2.0]*len(ecut_vec), color='g')
plt.plot(ecut_vec, [$conv_acell-energy_err_interval/2.0]*len(ecut_vec), color='g')

plt.xlabel('ecut (Ha)')
plt.ylabel('acell (Bohr)')
plt.savefig("$fig_path")
END

echo "Converged ecut $conv_ecut"
echo "Converged acell $conv_acell"
