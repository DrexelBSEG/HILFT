function Tdew = W2Td_IP(pbar,W)
%W2TD_IP Summary of this function goes here
%   Detailed explanation goes here
c14=100.45;
c15=33.193;
c16=2.319;
c17=0.17074;
c18=1.2063;

pbarpsia=pbar/2.036;
pw = W*pbarpsia/(W*1.0039+0.621945);
lnpw = log(pw);
pda = pbarpsia - pw;
Tdew = c14 + c15*lnpw + c16*lnpw.^2 + c17*lnpw.^3;
Tdew = Tdew + exp(log(c18) + 0.1984);

end

