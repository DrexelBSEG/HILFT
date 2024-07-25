function [mDA,v] = mDot(f,t,p,w)

pSI = p.*6895; % convert psi to Pa 
flowSI = f.*0.0004719; %convert cfm to m3/s
tC = 5/9.*(t - 32); % convert F to C
v = 0.287042.*(tC + 273.15).*(1+1.607858.*w)./(pSI/1000);
mDA = flowSI./v; % kg/s 