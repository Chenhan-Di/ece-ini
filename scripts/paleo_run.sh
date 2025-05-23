#!/bin/sh
#SBATCH -p your_partition_name
#SBATCH -A your_account_name
#SBATCH --job-name=pism_paleo
#SBATCH --time=HH:MM:SS
#SBATCH --nodes=1
#SBATCH --mem=8G
##SBATCH --ntasks=4
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --output=slurm.out

# OpenMPI settings
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

mpiexec -n 32 pismr -i input_file.nc \
-bootstrap -Mx 152 -My 282 -Mz 101 -Mbz 11 -z_spacing equal -Lz 4000 -Lbz 2000 -skip -skip_max 10 \
-grid.recompute_longitude_and_latitude false -periodicity none -ys -125000 -ye -8000 \
-atmosphere given,elevation_change,delta_T,precip_scaling \
-atmosphere.given.periodic true \
-atmosphere_given_file atmosphere_given_file.nc \
-atmosphere_lapse_rate_file atmosphere_lapse_rate_file.nc \
-atmosphere_precip_scaling_file atmosphere_precip_scaling_file.nc \
-atmosphere_delta_T_file atmosphere_delta_T_file.nc \
-temp_lapse_rate 6.5 \
-surface pdd -surface.pdd.refreeze 0.6 -surface.pdd.factor_snow 5.04000e-03 -surface.pdd.factor_ice 1.24900e-2 \
-sea_level constant,delta_sl -ocean_delta_sl_file ocean_delta_sl_file.nc \
-energy.bedrock_thermal.file bedrock_thermal_file.nc \
-front_retreat_file front_retreat_file.nc \
-sia_e $esia -ssa_e $essa \
-stress_balance.sia.max_diffusivity 500000 \
-stress_balance ssa+sia \
-topg_to_phi $pmin,$pmax,$zmin,$zmax \
-pseudo_plastic -pseudo_plastic_q $q \
-till_effective_fraction_overburden 0.02 -tauc_slippery_grounding_lines \
-ts_file "${opath}ts_${ofile}.nc" -ts_times -1250000:500:-8000   \
-extra_file "${opath}ex_${ofile}.nc" -extra_times -1250000:10000:-8000  \
-extra_vars diffusivity,temppabase,tempicethk_basal,bmelt,tillwat,velsurf_mag,mask,thk,topg,usurf \
-o "${opath}${ofile}.nc" 2>&1 | grep -v "node" > "your_logs_path/out.${ofile}"

mpiexec -n 32 pismr -i input_file.nc \
-bootstrap -Mx 152 -My 282 -Mz 101 -Mbz 11 -z_spacing equal -Lz 4000 -Lbz 2000 -skip -skip_max 10 \
-grid.recompute_longitude_and_latitude false -grid.registration center -periodicity none -ys -8000 -ye 0 -regrid_file "${opath}${ofile}.nc" -regrid_vars litho_temp,thk,enthalpy,tillwat,basal_melt_rate_grounded \
-surface given,elevation_change -surface.given.periodic true \
-surface_given_file surface_give_file.nc \
-surface_elevation_change_file surface_elevation_change_file.nc -surface.elevation_change.periodic yes \
-smb_adjustment shift -smb_lapse_rate $lapse \
-energy.bedrock_thermal.file bedrock_thermal_file.nc \
-front_retreat_file front_retreat_file.nc \
-sia_e $esia -ssa_e $essa \
-stress_balance ssa+sia \
-topg_to_phi $pmin,$pmax,$zmin,$zmax \
-pseudo_plastic -pseudo_plastic_q $q \
-till_effective_fraction_overburden 0.02 -tauc_slippery_grounding_lines \
-ts_file "${opath}ts_${ofile}_100y.nc" -ts_times -8000:1:0   \
-extra_file "${opath}ex_${ofile}_100y.nc" -extra_times -100:1month:0   \
-extra_vars diffusivity,temppabase,tempicethk_basal,bmelt,tillwat,velsurf_mag,mask,thk,topg,usurf,climatic_mass_balance \
-o "${opath}${ofile}_100y.nc" 2>&1 | grep -v "node" > "logs/out.${ofile}_100y"

echo "finished at :$(date)" >> $logs
