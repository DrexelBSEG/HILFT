function [uW] = uHumRat(tf,rh)
    % Calculate the uncertainty of the humidity ratio given RH in %
    % and T in F. Based on a curve fit using calculations from EES with 
    % an RH absolute uncertainty of 2 % and T absolute uncertainty of 0.2 F.
    a = 3.35783263e-04;
    b = -6.41986586e-07;
    c = -1.18522022e-05;
    d = 1.57189145e-08;
    e = 1.61622484e-07;
    
    uW = a + b*rh + c*tf + d*rh.*tf + e*tf.*2;