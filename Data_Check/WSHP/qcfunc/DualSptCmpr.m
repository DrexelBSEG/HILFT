function sys_perform_dual = DualSptCmpr(y,spt_high,spt_low,range,error_thres,time_thres)
%SYSPERFORMANCE Summary of this function goes here
%   Detailed explanation goes here

sys_perform_dual.time_high = sum((y(range)-spt_high(range))>error_thres);
sys_perform_dual.time_low = sum((spt_low(range)-y(range))>error_thres);

if sys_perform_dual.time_high>time_thres
    too_high = 1;
else
    too_high = 0;
end

if sys_perform_dual.time_low>time_thres
    too_low = 1;
else
    too_low = 0;
end

if (too_low == 0 && too_high == 0)
    sys_perform_dual.flag = 'Pass';
else
    sys_perform_dual.flag = 'Fail';
end

end

