% WSHP Cooling Power Consumption
function pow = predict_hp_cool_power(T_loa_in, T_sou_in, y_speed)
p_cool_nom=1.335; % Nominal Cooling Power (kW)
p_shift=0.12; % Power Offset (kW) -> Due to continuous fan operation
coeff = [1.4560,-0.0435,-0.0005,-0.0044,0.0004,0.0009];
pow_wo_speed = biquadratic(T_loa_in, T_sou_in, coeff)*p_cool_nom; % Power w/o Speed
pow=y_speed.*pow_wo_speed+p_shift; % Power scaled by speed
end

function res = biquadratic(x1, x2, coeff)
res = coeff(1) + (coeff(2)+coeff(3)*x1).*x1 + (coeff(4)+coeff(5)*x2).*x2 + coeff(6)*x1.*x2;
end