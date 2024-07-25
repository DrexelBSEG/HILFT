function uW = humd_uncrtn(P,Td)
% This function calcualte the uncertainty of the humidity ratio that is
% calcualted from pressure and dewpoint temperature

% Equation to calculate humidity ratio from pressure and dewpoint
% W = Td2W(p_kPa,T_C)
% Uncertainty of w
% uW = sqrt( uP^2*d(Td2W)/dP^2 + uTd^2*d(Td2W)/dTd^2 )

% Measurement uncertainty
uP = 0.001; % [kPa]
uTd = 0.4;  % [°C]


%% finite difference method
% Finite difference step size
h = double(sqrt(eps(single(1.0))));
hp = h*abs(P);
hTd = h*abs(Td);

% Central difference derivatives
df_dP = ( Td2W(P+hp,Td) - Td2W(P-hp,Td) ) / (2*hp) ;
df_dTd = ( Td2W(P,Td+hTd) - Td2W(P,Td-hTd) ) / (2*hTd) ;

%% Uncertainty of humidity ratio
uW = sqrt( uP^2*df_dP^2 + uTd^2*df_dTd^2 );

end

