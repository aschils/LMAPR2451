#!/bin/bash
abinit < "../input/bismuth.files" >& log_band
echo "######### SECOND SIMU ##########" >> log_band
abinit < "../input/bismuth_band.files" >> log_band
export PYTHONPATH="${PYTHONPATH}/usr/local/lib/python2.7/site-packages:/usr/lib/python2.7/site-packages"
./../figures/plot_band_structure.py
