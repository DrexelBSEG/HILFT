function ddemand_rel = kpi_demand_change_relative(ref_demand,flex_demand)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_demand: reference demand [W]
% flex_demand: flexible demand [W]
%% Output
% ddemand_rel: demand change percentage [-]
%% Main
ddemand_mean = mean(ref_demand) - mean(flex_demand);
ddemand_rel = ddemand_mean/mean(ref_demand);
end