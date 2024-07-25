function W = Td2W(P_kPa,Td_C)
%PW2W Summary of this function goes here
%   Detailed explanation goes here
PW = TC2pw(Td_C);
W = 0.621945*PW/(P_kPa-PW);
end

