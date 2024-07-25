function emu_accuracy = EmuAccuracy_hourly(sim,emu,unctrn,threshold)
% This function calcualte the hourly average difference between simulated
% and emulated values, and compare it with the hourly measurement uncertainy, 
% if none of the hourly error is outside the uncertainty band, case is passed.

for i=1:24
    % timestep of the hour
    timestep = i*60;
    % tempory array
    sim_temp = sim(timestep-59:timestep);
    emu_temp = emu(timestep-59:timestep);
    unctrn_temp = unctrn(timestep-59:timestep);
    % mean value
    sim_mean(i) = mean(sim_temp);
    emu_mean(i) = mean(emu_temp);
    unctrn_mean(i) = mean(unctrn_temp);
    if (sim_mean(i)~=0)
        % percentage error
        per_error(i) = (emu_mean(i) - sim_mean(i))/sim_mean(i);
        % significant percentage error
        if  (emu_mean(i) - abs(unctrn_mean(i)) - sim_mean(i)) > 0
            per_error_sgfnt(i) = (emu_mean(i) - abs(unctrn_mean(i)) - sim_mean(i))/sim_mean(i);
        elseif (emu_mean(i) + abs(unctrn_mean(i)) - sim_mean(i)) < 0
            per_error_sgfnt(i) = (emu_mean(i) + abs(unctrn_mean(i)) - sim_mean(i))/sim_mean(i);
        else
            per_error_sgfnt(i) = nan;
        end
    else
        per_error(i) = nan;
        per_error_sgfnt(i) = nan;
    end
end

%% output results
emu_accuracy.unctrn_mean = unctrn_mean;
emu_accuracy.sim_mean = sim_mean;
emu_accuracy.emu_mean = emu_mean;
emu_accuracy.per_error = per_error;
emu_accuracy.per_error_sgfnt = per_error_sgfnt;
% check if data pass
if any(abs(per_error_sgfnt)>threshold)
    emu_accuracy.flag = 'Warning';
else
    emu_accuracy.flag = 'Pass';
end

end

