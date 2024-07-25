function sys_perform_sngl = SnglSptCmprChw(y,spt,dir,e_tol,time_tol,ch_on,ch_power)
% dir	+1:y-spt, -1:spt-y

sys_perform_sngl.time_notmet = 0;
for i=1:length(y)
% determine whether chiller is on
    if (ch_on(i)>0 && ch_power(i)>900 && (y(i)-spt(i)*dir>e_tol))
        sys_perform_sngl.time_notmet = sys_perform_sngl.time_notmet+1;  
    end
end
if sys_perform_sngl.time_notmet<=time_tol
    sys_perform_sngl.flag = 'Pass';
else
    sys_perform_sngl.flag = 'Warning';
end

end

