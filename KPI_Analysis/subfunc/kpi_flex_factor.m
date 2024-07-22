function ff = kpi_flex_factor(load_lowprice,time_lowprice,load_highprice,time_highprice)
%% Notes
% Author: Zhelun Chen
% Date: 12/09/2022
%% Inputs
% load_lowprice: demand during low price time [W]
% time_lowprice: low price time length [hr]
% load_highprice: demand during high price time [W]
% time_highprice: high price time length [hr]
%% Output
% ff: flexibility factor, unit [-]
%% Main
% energy use at lower price
energy_lowprice = mean(load_lowprice)*time_lowprice;
% energy use at high price
energy_highprice = mean(load_highprice)*time_highprice;
% flexibility factor
ff = (energy_lowprice-energy_highprice)/(energy_lowprice+energy_highprice);
end