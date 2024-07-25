function w = omega(P,T,RH)
% P [Pa]
% T [°C]
% RH [%]

TC = T;
TK = TC + 273.15; % convert from C to K

C8 = -5.8002206e3;
C9 = 1.3914993;
C10 = -4.8640239e-2;
C11 = 4.1764768e-5;
C12 = -1.4452093e-8;
C13 = 6.5459673;  

% Saturation pressure in Pa
pSat = exp(C8./TK + C9 + C10.*TK + C11.*TK.^2 + C12.*TK.^3 + C13.*log(TK));  

% Vapor pressure in Pa
if (RH > 1) 
     RH = RH./100;
end
pW = RH.*pSat;

w = 0.622.*pW./(P - pW);