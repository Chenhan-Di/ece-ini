#!/bin/sh
#SBATCH -p your_partition_name
#SBATCH -A your_account_name
#SBATCH --job-name=pism_const
#SBATCH --time=HH:MM:SS
#SBATCH --nodes=1
#SBATCH --mem=8G
##SBATCH --ntasks=4
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --output=slurm.out

# export OMPI_MCA_btl_openib_warn_no_device_params_found=0
# export OMPI_MCA_btl=^openib
# export OMPI_MCA_pml=ucx

# export OMPI_MCA_pml_ucx_verbose=100
# export OMPI_MCA_pml_base_verbose=100

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

logs="your_logs_path/your_logs_name"

echo "stared at :$(date)" >> $logs

mpiexec -n 16 pismr -i input_file.nc \
-bootstrap -Mx 152 -My 282 -Mz 101 -Mbz 11 -z_spacing equal -Lz 4000 -Lbz 2000 -skip -skip_max 10 \
-grid.recompute_longitude_and_latitude false -periodicity none -ys -50000 -ye 100 \
-surface given,elevation_change -surface.given.periodic true \
-surface_given_file surface_given_file.nc \
-surface_elevation_change_file surface_elevation_change_file.nc -surface.elevation_change.periodic yes \
-smb_adjustment shift -smb_lapse_rate $lapse \
-energy.bedrock_thermal.file bedrock_thermal_file.nc \
-front_retreat_file front_retreat_file.nc \
-sia_e $esia -ssa_e $essa \
-stress_balance ssa+sia \
-topg_to_phi $pmin,$pmax,$zmin,$zmax \
-pseudo_plastic -pseudo_plastic_q $q \
-till_effective_fraction_overburden 0.02 -tauc_slippery_grounding_lines \
-ts_file "${opath}ts_${ofile}.nc" -ts_times -50000:100:100 \
-extra_file "${opath}ex_${ofile}_100y.nc" -extra_times 0:1month:100   \
-extra_vars diffusivity,temppabase,tempicethk_basal,bmelt,tillwat,velsurf_mag,mask,thk,topg,usurf,climatic_mass_balance \
-o "${opath}${ofile}.nc" 2>&1 | grep -v "node" > "your_logs_path/out.${ofile}"

echo "finished at :$(date)" >> $logs

# Calculate the RMSE
ref_usurf_file="ref_usurf_file.nc"
ref_velmag_file="ref_velmag_file.nc"
output_file="${opath}cal_${ofile}.nc"
ex_file="${opath}ex_${ofile}_100y.nc"
temp_usurf="${ofile}_usurf.nc"
temp_velsure="${ofile}_velsurf.nc"
temp_cmb="${ofile}_cmb.nc"

cdo timmean -seltimestep,1080/1199 -selname,usurf $ex_file $temp_usurf
cdo timmean -seltimestep,1080/1199 -selname,velsurf_mag $ex_file $temp_velsure

cdo timmean -seltimestep,1188/1199 -selname,climatic_mass_balance $ex_file $temp_cmb

cdo merge $temp_usurf $temp_velsure $temp_cmb $output_file


rmse_usurf=$(cdo -output -sqrt -fldmean -sqr -sub -selname,usurf $output_file -selname,surface $ref_usurf_file)
rmse_velsurf=$(cdo -output -sqrt -fldmean -sqr -sub -selname,velsurf_mag $output_file -selname,land_ice_surface_velocity_magnitude $ref_velmag_file)

echo "RMSE(usurf) = ${rmse_usurf}, RMSE(velsurf_mag) = ${rmse_velsurf}" >> $logs

rm $temp_usurf $temp_velsure $temp_cmb
