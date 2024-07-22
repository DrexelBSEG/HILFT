function dpmvact = kpi_pmvact_change(ref_pmvact,flex_pmvact)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_pmvact: reference discomfort time [min]
% flex_pmvact: flexible discomfort time [min]
%% Output
% dpmvact: discomfort time change [min]  
%% Main
dpmvact = ref_pmvact - flex_pmvact;
end