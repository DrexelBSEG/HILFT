function dbehavior = kpi_behavior_change(ref_behavior,flex_behavior)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_behavior: reference number of behavior persist time [count-min]
% flex_behavior: flexible number of behavior persist time [count-min]
%% Output
% : discomfort time change [min]  
%% Main
dbehavior = ref_behavior - flex_behavior;
end