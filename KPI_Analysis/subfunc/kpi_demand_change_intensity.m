function ddemand_int = kpi_demand_change_intensity(ref_demand,flex_demand,area)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_demand: reference demand [W]
% flex_demand: flexible demand [W]
%% Output
% ddemand_int: demand change intensity [W/m2]
%% Main
ddemand_mean = mean(ref_demand) - mean(flex_demand);
ddemand_int = ddemand_mean/area;
end