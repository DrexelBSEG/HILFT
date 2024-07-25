function sys_perform_sngl = SnglSptCmprWarn(y,spt,dir,e_tol,time_tol)
% dir	+1:y-spt, -1:spt-y
sys_perform_sngl.time_notmet = sum((y-spt)*dir>e_tol);  

if sys_perform_sngl.time_notmet<=time_tol
    sys_perform_sngl.flag = 'Pass';
else
    sys_perform_sngl.flag = 'Warning';
end

end

