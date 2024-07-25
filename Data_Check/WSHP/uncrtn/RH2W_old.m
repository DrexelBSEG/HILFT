function W = RH2W(RH,T,P)

TK = T+273.15;

% coefficient
a=-5.8002206*10^3;
b=1.3914993;
c=-4.8640239*10^-2;
d=4.1764768*10^-5;
e=-1.4452093*10^-8;
f=6.5459673;

M = 0.62198;

% saturation pressure
ps=(exp(a/TK+b+c*...
           TK+d*TK^2+...
               e*TK^3+f*log(TK)));
% water vapor pressure
pv = RH*ps/100;
% humidity ratio
W = M*pv/(P-pv);

end

