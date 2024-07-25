function [w,uw] = uRelHumd2uHumdRatio_ASHRAE2021_SI(RH,uRH,T,uT,P)
%% Notes
% Uncertainty propagation from relative humidity (RH) to humidity ratio (w)
% Use central difference method
% Adopt ASHRAE 2021 equations
%% Inputs
% RH:  	Relative humidity [%]
% uRH:	Relative humidity uncertainty [%]
% T:  	Temperature [C]
% uT:  	Temperature uncertianty [C]
% P:  	Pressure [kPa]
%% Outputs
% w:    Humidity ratio [kg/kg]
% uw:   Humidity ratio uncertainty [kg/kg]
%% Main
% Humidity ratio
w = RelHumd2HumdRatio_ASHRAE2021_SI(RH,T,P);
% Specify finite difference step size
h = double(sqrt(eps(single(1.0))));
hRH = h*abs(RH);
hT = h*abs(T);
% Central difference derivatives
dw_dRH = ( RelHumd2HumdRatio_ASHRAE2021_SI(RH+hRH,T,P) - RelHumd2HumdRatio_ASHRAE2021_SI(RH-hRH,T,P) ) / (2*hRH) ;
dw_dT = ( RelHumd2HumdRatio_ASHRAE2021_SI(RH,T+hT,P) - RelHumd2HumdRatio_ASHRAE2021_SI(RH,T-hT,P) ) / (2*hT) ;
% Uncertainty of humidity ratio
uw = sqrt( uRH^2*dw_dRH^2 + uT^2*dw_dT^2 );
end

