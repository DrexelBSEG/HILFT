function w = RelHumd2HumdRatio_ASHRAE2021_SI(RH,T,P)
%% Notes
% Source: ASHRAE 2021 Handbook Chapter 1 Equation (8)(19)(21)
% Inputs
% RH:   Relative Humidity [%]
% T:    Temperature [C]
% P:    Pressure [kPa]
% Outputs
% pw:   Water vapor pressure [kPa]
%% Main
% saturation pressure
pws = Temp2SatPres_ASHRAE2021_SI(T);
% water vapor pressure
pw = RH.*pws/100;
% humidity ratio
w = 0.621945*pw./(P-pw);
end

