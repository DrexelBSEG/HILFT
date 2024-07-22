function [Tz_hspt,Tz_cspt]=DefaultSettingHP(sys_status,Season_type,Occupied)
if Season_type==1
    if Occupied==1 
        Tz_hspt = 68;     % [F]
        Tz_cspt = 78;     % [F]
    else
        Tz_hspt = 55;     % [F]
        Tz_cspt = 90;     % [F]
    end
else
    if Occupied==1 
        Tz_hspt = 68;     % [F]
        Tz_cspt = 78;     % [F]
    else
        Tz_hspt = 55;     % [F]
        Tz_cspt = 90;     % [F]
    end
end