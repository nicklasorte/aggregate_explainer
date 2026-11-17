# Data sources

| File | Source | Notes |
| --- | --- | --- |
| `7Ghz 0azi 0ele EIRP.xlsx` | [nicklasorte/FSS_Neighborhood](https://github.com/nicklasorte/FSS_Neighborhood/blob/main/7Ghz%200azi%200ele%20EIRP.xlsx), commit `af0f1ed` | Base station EIRP percentiles (0th to 100th, every 10th) for the 0° azimuth, 0° elevation cut, in dBm. Used by `init_sim_folder_FSS_neigh_rev25_fdr_github.m`, which normalizes it to its median. |

Code copied or adapted from other repositories:

| File | Source |
| --- | --- |
| `src/p2108_terrestrial_clutter_loss_vector_rev2.m` | Adapted from `p2108_terrestrial_clutter_loss_vector.m` in [nicklasorte/general_terrestrial_pathloss](https://github.com/nicklasorte/general_terrestrial_pathloss), commit `17e5134`, and checked against ITU-R P.2108-1 (09/2021) and [NTIA/p2108](https://github.com/NTIA/p2108). |
| `src/sim_reliability_grid_rev1.m` | Reliability grid from `init_sim_folder_FSS_neigh_rev25_fdr_github.m` (FSS_Neighborhood). |
