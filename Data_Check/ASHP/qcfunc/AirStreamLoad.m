function [Qsen,Qlat] = AirStreamLoad(Tin,Tout,win,wout,m)
%% Inputs
% Tin:  zone inlet air temperature [°C], i.e., supply air temperature
% Tout: zone outlet air temperature [°C], i.e., zone air temperature
% win:  zone inlet air humidity ratio [kg/kg], i.e., supply air humidity ratio
% wout: zone outlet air humidity ratio [kg/kg], i.e., zone air humidity ratio
% m:    zone inlet air mass flow rate [kg/s], i.e., supply air mass flow rate
%% Outputs
% Qsen: zone sensible load [W]
% Qlat: zone latent load [W]
%% Main
% properties
cpa = 1.006;
cpw = 1.86;
hwe = 2501;
% Enthalpy
hin = cpa*Tin + win*(cpw*Tin + hwe);
hout = cpa*Tout + wout*(cpw*Tout + hwe);
% Loads
Qtot = 1000*m*(hin - hout);
Qsen = 1000*m*(cpa + cpw*min(win,wout))*(Tin - Tout);
Qlat = Qtot - Qsen;
end