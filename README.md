# Initialization Parameter Scanning for PISM

This project is for the initialization parameter scanning using the Parallel Ice Sheet Model (PISM). It includes the sampling and the job submission script for PISM.

## Script Descriptions

### Sampling

- `lhs.ipynb`: Latin Hypercube Sampling
- `multi_objective.ipynb`: Multi-objective Bayesian Optimization and Calibration (Mainly Refers to the Botorch documentation)
- `pism_rmse.json`: The dataset, including the parameters and the objective (rmse)

### Sbatch Scripts

- `variable.txt`: The input variables.
- `constant_run.sh`: The command for spin-up under constant climate. It requires the surface mass balance files, and calculate the RMSE for last 10 years using `cdo`. 
- `paleo_run.sh`: The command for spin-up under paleo climate. It requires the atmosphere files and the surface mass balance files.
- `transient_run.sh`: The command for the run under present-day climate. It requires the surface mass balance files, and running locally.

## Reference

The code is mainly refers to the Botorch documentation for the multi-objective Bayesian optimization, please see: https://botorch.org/docs/tutorials/

The sbatch scripts is for the PISM settings, for more informations about PISM, please see:  https://www.pism.io/

## License

See [LICENSE](LICENSE)
