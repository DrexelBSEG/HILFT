function W = RH2W(RH,T,P)

% saturation pressure
ps = TC2pw(T);
% water vapor pressure
pv = RH*ps/100;
% humidity ratio
W = 0.621945*pv/(P-pv);

end

