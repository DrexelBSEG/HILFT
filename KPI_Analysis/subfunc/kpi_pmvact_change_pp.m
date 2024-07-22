function dpmvact_pp = kpi_pmvact_change_pp(ref_pmvact,flex_pmvact,time)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% ref_pmvact: reference discomfort time [min]
% flex_pmvact: flexible discomfort time [min]
% time: length of the evaluted period [min]
%% Output
% dpmvact_pp: discomfort time percentage per period [-]  
%% Main
dpmvact_pp = (ref_pmvact - flex_pmvact)/time;
end