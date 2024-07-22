function ddemand_mean = kpi_demand_change(ref_demand,flex_demand)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_demand: reference demand [W]
% flex_demand: flexible demand [W]
%% Output
% ddemand_mean: demand change [W]
%% Main 
ddemand_mean = mean(ref_demand) - mean(flex_demand);
end