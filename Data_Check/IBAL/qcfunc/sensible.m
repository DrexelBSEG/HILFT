function [q] = sensible(t1,t2,w1,w2,mDA)

tC1 = 5/9.*(t1 - 32); % convert F to C
tC2 = 5/9.*(t2 - 32);

cp1 = 1.006 + 1.86*w1; % kJ/kg-K
cp2 = 1.006 + 1.86*w2;

q = (mDA.*(cp2.*tC2 - cp1.*tC1)).*1000; % sensible load in W