function cost = kpi_tou_cost_acc(Q, tou, stepsize)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%
%% Inputs
% Q: power measurement [kW]
% tou: time-of-use price corresponding to each measurement [$/kWh]
% stepsize: power measurement interval [hour]
%
%% Outputs
% cost: total cost [$] 
%
%% Main
% energy consumed at each timestep
E = Q*stepsize;

% cost = sum of price at each timestep
cost = sum(E.*tou);

end