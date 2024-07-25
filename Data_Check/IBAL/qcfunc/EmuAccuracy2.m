function emu_accuracy = EmuAccuracy2(sim,emu,e_thres,rate_thres)

rate = sum(abs(sim-emu)>e_thres)/length(sim);
if (rate<=rate_thres)
    emu_accuracy.flag = 'Pass';
else
    emu_accuracy.flag = 'Fail';
end
emu_accuracy.rate = rate;
end

