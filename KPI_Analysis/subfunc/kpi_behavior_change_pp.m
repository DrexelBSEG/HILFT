function dbehavior_pp = kpi_pmvact_change_pp(ref_behavior,flex_behavior,time)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_behavior: reference number of behavior persist time [count-min]
% flex_behavior: flexible number of behavior persist time [count-min]
% time: length of the evaluted period [min]
%% Output
% dbehavior_pp: count of a behavior per period [-]  
%% Main
dbehavior_pp = (ref_behavior - flex_behavior)/time;
end