#!/bin/bash

#convergence regarding ngkpt if prev_etotal - cur_etotal < delta_etotal_conv"
delta_etotal_conv="0.01"

ref_in_file="../input/bismuth_tsmear_kpt_conv.in"

#path of input file with current value of ngkpt
temp_input_file_path="temp_input_file.in"


tsmear="0.1"
has_converged_tsmear="0"
prev_acell1="9999999"
prev_acell2="9999999"
prev_acell3="9999999"

while [ "$has_converged_tsmear" -ne "1" ]
do

  echo "tsmear $tsmear"

  ngkpt="3"
  prev_etotal="9999999"
  cur_etotal="0"
  has_converged_ngkpt="0"
  ngkpt_vec=""
  etotal_vec=""

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
../psps/LDA/83bi.pspnc"

    #add ngkpt value to reference .in file, thus building the temporary .in file
    { cat $ref_in_file; echo "ngkpt $ngkpt $ngkpt $ngkpt"; } > $temp_input_file_path
    #add tsmear value
    echo "tsmear $tsmear" >> $temp_input_file_path

    #launch abinit with ngkpt value of current iteration
    log="log_tsmear_$tsmear-ngkpt_$ngkpt"
    echo "$abinit_files" | abinit >& $log
    #delete temporary .in file
    rm $temp_input_file_path

#     output_file_str=$(cat $output_file_path)
#     last_part_output_file_str=$(
#     python << END
# output_file_str = """$output_file_str"""
# output_file_str = output_file_str.split("OUTPUT")
# print(output_file_str[len(output_file_str)-1])
# END
# )

    cur_etotal=$(sed -n -e '/END DATASET(S)/,$p' $output_file_path | awk '{for(i=1;i<=NF;i++) if ($i=="etotal") print $(i+1)}')
    #From scientific notation to decimal, bc does not handle correctly scientific notation
    cur_etotal=$(python -c "print '%.16f' % float('$cur_etotal')")
    delta_etotal=$(python -c "print '%.16f' % abs(float('$prev_etotal') - float('$cur_etotal'))")
    bc_arg="$delta_etotal < $delta_etotal_conv"
    has_converged_ngkpt=$(bc <<< $bc_arg)


    if $first_iter_ngkpt;
    then
      ngkpt_vec="$ngkpt"
      etotal_vec="$cur_etotal"
      first_iter_ngkpt=false
    else
      ngkpt_vec="$ngkpt_vec $ngkpt"
      etotal_vec="$etotal_vec $cur_etotal"
    fi

    echo "ngktp $ngkpt"
    echo $cur_etotal

    prev_etotal=$cur_etotal
    ((ngkpt++))
  done

  acell_line=$(sed -n -e '/END DATASET(S)/,$p' $output_file_path | grep " acell ")
  #acell_line=$(grep " acell " $output_file_path)

  echo $acell_line

  python_out=$(
  python << END
acells_line = "$acell_line"
acells = acells_line.split(' ')
acells = filter(None, acells) #remove empty strings from list
acells.pop(0) #remove useless acell keyword
acells.pop(len(acells)-1) #remove useless Bohr keyword
acells = map(float, acells)
acell1_conv = abs(float("$prev_acell1")-acells[0]) < float("$delta_etotal_conv")
acell2_conv = abs(float("$prev_acell2")-acells[1]) < float("$delta_etotal_conv")
acell3_conv = abs(float("$prev_acell3")-acells[2]) < float("$delta_etotal_conv")
tsmear_converged = acell1_conv and acell2_conv and acell3_conv
if tsmear_converged:
  print("1")
else:
  print("0")

print(acells[0])
print(acells[1])
print(acells[2])
END
)

  #echo "$prev_acell1 $prev_acell2 $prev_acell3"
  #echo "$python_out"
  has_converged_tsmear=$(echo "$python_out" | sed '1q;d')
  prev_acell1=$(echo "$python_out" | sed '2q;d')
  prev_acell2=$(echo "$python_out" | sed '3q;d')
  prev_acell3=$(echo "$python_out" | sed '4q;d')

  tsmear=$(bc <<< "$tsmear+0.1")
done
