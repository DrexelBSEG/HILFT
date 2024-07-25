function [Qsen,Qlat] = AirStreamLoad(Tin,Tout,win,wout,m)
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