#!/bin/bash
abinit < "../input/bismuth_so.files" >& log_band
echo "######### SECOND SIMU ##########" >> log_band
abinit < "../input/bismuth_band_so.files" >> log_band
export PYTHONPATH="${PYTHONPATH}/usr/local/lib/python2.7/site-packages:/usr/lib/python2.7/site-packages"
./../figures/plot_band_structure.py
