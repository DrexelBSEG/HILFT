function emu_accuracy = EmuAccuracy(sim,emu,rmse_thres)
%EMUACCURACY Summary of this function goes here
%   Detailed explanation goes here
% accuracy_opt: 1-rmse, 2-range and in range rate
RMSE = sqrt(immse(sim,emu));
sim_mean = mean(sim);
emu_mean = mean(emu);
NRMSE = RMSE/sim_mean;

emu_accuracy.rmse = RMSE;
emu_accuracy.nrmse = NRMSE;
emu_accuracy.sim_mean = sim_mean;
emu_accuracy.emu_mean = emu_mean;

if RMSE <= rmse_thres
    emu_accuracy.flag = 'Pass';  
else
    emu_accuracy.flag = 'Warning';
end

end

