function cost = kpi_tou_cost_aasc2_oneday(Q_peak,Q_nonpeak,tou_peak,tou_nonpeak)
%% Notes
% TOU program according to Con-Edison AA-SC2
% Author: Zhelun Chen
% Date: 12/09/2022
%
% Definition of billable demand:
% For each day in a billing cycle, the maximum daily demand shall be calculated for each time period applicable
% to that day. The Billable Demands shall be determined by calculating the average of the three highest
% maximum daily demands occurring in each time period for the applicable billing period. All maximum daily
% demand values shall be established by calculating the highest integrated 60-minute demand ending in each
% day and being entirely comprised of intervals ending in the same time period (on-peak, off-peak).
%
% This function is a lite version of teh AA-SC2 program where only one day cost is evaluted. Therefore, the
% two highest demands in peak and nonpeak periods respectively are billed. Instead of the three hightest
% maximum daily demands as stated above.
%
%% Inputs
% Q_peak: power measurements during peak [kW]
% Q_nonpeak: power measurements during nonpeak [kW]
% tou_peak: price during peak [$/kW]
% tou_nonpeak: price during nonpeak [$/kW]
%
%% Outputs
% cost: total monthly cost [$], assuming the evaluated day contribute to the billable demand 
%
%% Main
% integrated 60-minute demand
Q_peak_mean = movmean(Q_peak,60,'Endpoints','discard');
Q_nonpeak_mean = movmean(Q_nonpeak,60,'Endpoints','discard');

% cost
cost = max(Q_peak_mean)*tou_peak + max(Q_nonpeak_mean)*tou_nonpeak;

end