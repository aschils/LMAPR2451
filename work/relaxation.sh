abinit_files="../input/relaxation.in
../output/relaxation.out
tbase1_xi
tbase1_xo
tbase1_x
../psps/LDA/83bi.pspnc
"

echo "$abinit_files" | abinit >& log_relaxation.txt
