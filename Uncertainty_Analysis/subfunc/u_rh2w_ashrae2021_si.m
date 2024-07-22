function u_w = u_rh2w_ashrae2021_si(RH,u_RH,T,u_T,P,u_P)
%% Notes
% Purpose: Calculate humidity ratio uncertainty
% Source: ASHRAE 2021 Handbook Chapter 1 Equation (8)(19)(21)
% Inputs
% RH:   Relative humidity [%]
% u_RH: Relative humidity uncertainty [%]
% T:    Temperature [C]
% u_T:  Temperature uncertainty [C]
% P:    Pressure [kPa]
% u_P:  Pressure uncertainty [kPa]
% Outputs
% u_w:  Humidity ratio uncertainty [kg/kg]
%% Main
% Finite difference step size
h = double(sqrt(eps(single(1.0))));
hRH = h*abs(RH);
hT = h*abs(T);
hP = h*abs(P);

% Central difference derivatives
df_dRH = ( rh2w_ashrae2021_si(RH+hRH,T,P) - rh2w_ashrae2021_si(RH-hRH,T,P) ) ./ (2*hRH) ;
df_dT = ( rh2w_ashrae2021_si(RH,T+hT,P) - rh2w_ashrae2021_si(RH,T-hT,P) ) ./ (2*hT)  ;
df_dP = ( rh2w_ashrae2021_si(RH,T,P+hP) - rh2w_ashrae2021_si(RH,T,P-hP) ) ./ (2*hP)  ;

% return
u_w = sqrt( u_RH.^2 .* df_dRH.^2 + u_T.^2 .* df_dT.^2 + u_P.^2 .* df_dP.^2 );

end

