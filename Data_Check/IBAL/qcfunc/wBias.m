function [b,s] = wBias(location)
% The bias terms and bias uncertainty are calculated in 
% 'E:\EDrive\Tests\ZS\Characterization data\MinLatentLoad.ipynb' using 
% data taken at different airflow rates with the zone humidifiers and 
% heaters off
% see
% https://www.itl.nist.gov/div898/handbook/mpc/section5/mpc5332.htm#stddevbias
% for details of how these values were determined

% b = bias to subtract from the measurement
% s = the standard deviation of the corrected term
if strcmp(location,'ahu2')
    b = 0.000148;
    s = 2.062e-6;
elseif strcmp(location,'zs1')
    b = 0.000112;
    s = 2.322e-6;
elseif strcmp(location,'zs2')   
    b = -6.242e-5;
    s = 1.139e-6;
elseif strcmp(location,'ahu1')
    b = 0.000160;
    s = 1.239e-6;
elseif strcmp(location,'zs3') 
    b = -0.000127;
    s = 8.056e-7;
else % zs4
    b = -4.907e-5;
    s = 7.714e-7;
end