function [uq] = uQLatent(AV,rh2,tf2,rh1,tf1,w2,w1)
   % Calculate the uncertainty of the latent load using 
   % qLatent = mDot*(w2 - w1) where mDot is the mass flow rate
   % calculated by multiplying density by the airflow rate 
   % (cfm converted to m3/s) and w2 and w1 are the humidity
   % ratios at the outlet and inlet.   
    v = 0.83; % [m3/kg] specific volume. Based on the mean of some measurements
    mDot = AV/v*0.00047; % calculate mass flow rate [kg/s]. Convert cfm to m3/s
    dqdm = 2501*(w2-w1);
    dqdw2 = 2501*mDot;
    dqdw1 = -2501*mDot;
    um = 0.10*mDot; % Uncertainty in the airflow measurement is 10 %
    uw2 = uHumRat(tf2,rh2); % uncertainty of humidity ratio at inlet; from curve fit
    uw1 = uHumRat(tf1,rh1); % uncertainty of humidity ratio at inlet; from curve fit
    term1 = (dqdm.*um).*(dqdm.*um);
    term2 = (dqdw2.*uw2).*(dqdw2.*uw2);
    term3 = (dqdw1.*uw1).*(dqdw1.*uw1);
    terms = term1+term2+term3;
    uq = sqrt(terms)*1000;