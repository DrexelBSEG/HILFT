function uW = humd_uncrtn(RH,T,P)
% This function calcualte the uncertainty of the humidity ratio that is
% calcualted from RH and temperature

% Equation to calculate humidity ratio 
% W = RH2W(RH,T,P)
% Uncertainty of W
% uW = sqrt( uP^2*d(Td2W)/dP^2 + uTd^2*d(Td2W)/dTd^2 )

% Measurement uncertainty
uT = 0.25; % [°C]
if RH>90
    uRH = 0.03*RH;
else
    uRH = 0.02*RH;
end


%% finite difference method
% Finite difference step size
h = double(sqrt(eps(single(1.0))));
hRH = h*abs(RH);
hT = h*abs(T);

% Central difference derivatives
df_dRH = ( RH2W(RH+hRH,T,P) - RH2W(RH-hRH,T,P) ) / (2*hRH) ;
df_dT = ( RH2W(RH,T+hT,P) - RH2W(RH,T-hT,P) ) / (2*hT)  ;

%% Uncertainty of humidity ratio
uW = sqrt( uRH^2*df_dRH^2 + uT^2*df_dT^2 );

end

