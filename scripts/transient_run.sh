#!/bin/bash

opath="your_path"

source "variable.txt"
fq=$(printf "%.2f" "$q")
fpmin=$(printf "%.2f" "$pmin")
fpmax=$(printf "%.2f" "$pmax")
fzmin=$(printf "%.2f" "$zmin")
fzmax=$(printf "%.2f" "$zmax")
flapse=$(printf "%.2f" "$lapse")
fesia=$(printf "%.2f" "$esia")
fessa=$(printf "%.2f" "$essa")
ofile="your_output_file_name"

mpiexec -n 4 pismr \
-i input_file.nc \
-bootstrap -Mx 152 -My 282 -Mz 101 -Mbz 11 -z_spacing equal -Lz 4000 -Lbz 2000 -skip -skip_max 10 \
-grid.recompute_longitude_and_latitude false -grid.registration center -ys 0 -ye 165 -regrid_file "regrid_file.nc" -regrid_vars litho_temp,thk,enthalpy,tillwat,basal_melt_rate_grounded \
-periodicity none \
-surface given,elevation_change -surface.given.periodic false \
-surface_given_file surface_given_file.nc \
-surface_elevation_change_file surface_elevation_change_file.nc -surface.elevation_change.periodic no \
-smb_adjustment shift -smb_lapse_rate 0 \
-energy.bedrock_thermal.file bedrock_thermal_file.nc \
-front_retreat_file front_retreat_file.nc \
-sia_e $esia -ssa_e $essa \
-stress_balance ssa+sia \
-topg_to_phi $pmin,$pmax,$zmin,$zmax \
-pseudo_plastic -pseudo_plastic_q $q \
-till_effective_fraction_overburden 0.02 -tauc_slippery_grounding_lines \
-ts_file "${opath}ts_${ofile}.nc" -ts_times 0:1:165   \
-extra_file "${opath}ex_${ofile}.nc" -extra_times 0:1:165   \
-extra_vars diffusivity,temppabase,tempicethk_basal,bmelt,tillwat,velsurf_mag,mask,thk,topg,usurf,climatic_mass_balance \
-o "${ofile}.nc"
