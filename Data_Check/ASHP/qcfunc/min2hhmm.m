function [time_hhmm] = min2hhmm(time_min)
%MIN2HHMM Summary of this function goes here
%   Detailed explanation goes here
if mod(time_min,60)==0
    time_hhmm = [num2str(floor(time_min/60)) ':' num2str(mod(time_min,60)) '0'];
elseif mod(time_min,60)<10
    time_hhmm = [num2str(floor(time_min/60)) ':0' num2str(mod(time_min,60))];
else
    time_hhmm = [num2str(floor(time_min/60)) ':' num2str(mod(time_min,60))];
end
end

