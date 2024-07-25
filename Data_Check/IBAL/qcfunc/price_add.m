function price_acc = price_add(power,tou)
%PRICE_ADD Summary of this function goes here
%   Detailed explanation goes here
price_acc = zeros(1,length(power));
price_acc(1) = power(1)/1000*tou(1)/60;
for i=2:length(tou)
    price_acc(i) = price_acc(i-1) + power(i)/1000*tou(i)/60;
end
end

