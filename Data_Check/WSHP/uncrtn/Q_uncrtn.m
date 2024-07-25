function [uQsen,uQlat] = Q_uncrtn(Tin,Tout,RHin,RHout,Flow,P)
% This function calcualte the uncertainties of the sensible and latent loads,
% which are calcualted from the difference between inlet outlet conditions.
%% humidity ratio from dewpoint
HUMDin = RH2W(RHin,Tin,P);
HUMDout = RH2W(RHout,Tout,P);
%% individual uncertainties
uTin = 0.25;  % [°C]
uTout = 0.25;  % [°C]
uHUMDin = humd_uncrtn(RHin,Tin,P);
uHUMDout = humd_uncrtn(RHout,Tout,P);
uFlow = 0.03*Flow;
%% air properties
cpa = 1.006;
cpw = 1.86;
hwe = 2501;
%% Sensible load
% Derivative
% Qsen = 1000*m*(cpa + cpw*min(win,wout))*(Tin - Tout);
if HUMDin<HUMDout
    dQsen_dTin = 1000*Flow*(cpa + HUMDin*cpw);
    dQsen_dTout =  - 1000*Flow*(cpa + HUMDin*cpw);
    dQsen_dHUMDin = 1000*Flow*cpw*(Tin - Tout);
    dQsen_dHUMDout = 0;
    dQsen_dFlow = 1000*(Tin - Tout)*(cpa + HUMDin*cpw);
    dQlat_dTin = 0;
    dQlat_dTout =  1000*Flow*(cpa + HUMDin*cpw) - 1000*Flow*(cpa + HUMDout*cpw);
    dQlat_dHUMDin = 1000*Flow*(hwe + Tin*cpw) - 1000*Flow*cpw*(Tin - Tout);
    dQlat_dHUMDout =  - 1000*Flow*(hwe + Tout*cpw);
    dQlat_dFlow = 1000*Tin*cpa - 1000*Tout*cpa + 1000*HUMDin*(hwe + Tin*cpw) - 1000*HUMDout*(hwe + Tout*cpw) - 1000*(Tin - Tout)*(cpa + HUMDin*cpw);
else
    dQsen_dTin = 1000*Flow*(cpa + HUMDout*cpw);
    dQsen_dTout =   - 1000*Flow*(cpa + HUMDout*cpw);
    dQsen_dHUMDin = 0;
    dQsen_dHUMDout = 1000*Flow*cpw*(Tin - Tout);
    dQsen_dFlow = 1000*(Tin - Tout)*(cpa + HUMDout*cpw);
    dQlat_dTin = 0;
    dQlat_dTout =  1000*Flow*(cpa + HUMDin*cpw) - 1000*Flow*(cpa + HUMDout*cpw);
    dQlat_dHUMDin = 1000*Flow*(hwe + Tin*cpw) - 1000*Flow*cpw*(Tin - Tout);
    dQlat_dHUMDout =  - 1000*Flow*(hwe + Tout*cpw);
    dQlat_dFlow = 1000*Tin*cpa - 1000*Tout*cpa + 1000*HUMDin*(hwe + Tin*cpw) - 1000*HUMDout*(hwe + Tout*cpw) - 1000*(Tin - Tout)*(cpa + HUMDin*cpw);
end
%% Uncertainty
uQsen = sqrt( uTin^2*dQsen_dTin^2 + uTout^2*dQsen_dTout^2 + ...
    uHUMDin^2*dQsen_dHUMDin^2 + uHUMDout^2*dQsen_dHUMDout^2 + ...
    uFlow^2*dQsen_dFlow^2 );
uQlat = sqrt( uTin^2*dQlat_dTin^2 + uTout^2*dQlat_dTout^2 + ...
    uHUMDin^2*dQlat_dHUMDin^2 + uHUMDout^2*dQlat_dHUMDout^2 + ...
    uFlow^2*dQlat_dFlow^2 );
end

