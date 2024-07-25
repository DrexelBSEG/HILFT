function emu_accuracy = EmuAccuracy_hourly(sim,emu,unctrn,threshold)
% This function calcualte the hourly average difference between simulated
% and emulated values, and compare it with the hourly measurement uncertainy, 
% if none of the hourly error is outside the uncertainty band, case is passed.

for i=1:24
    % timestep of the hour
    timestep = i*60+1;
    % tempory array
    sim_temp = sim(timestep-59:timestep);
    emu_temp = emu(timestep-59:timestep);
    unctrn_temp = unctrn(timestep-59:timestep);
    % mean value
    sim_mean(i) = mean(sim_temp);
    emu_mean(i) = mean(emu_temp);
    unctrn_mean(i) = mean(unctrn_temp);
%     unctrn_mean(i) = sqrt(sumsqr(unctrn_temp/60));
    if (sim_mean(i)~=0)
        % percentage error
        rel_error(i) = (emu_mean(i) - sim_mean(i))/sim_mean(i);
        % significant percentage error
        if  (emu_mean(i) - abs(unctrn_mean(i)) - sim_mean(i)) > 0
            rel_error_sgfnt(i) = (emu_mean(i) - abs(unctrn_mean(i)) - sim_mean(i))/sim_mean(i);
        elseif (emu_mean(i) + abs(unctrn_mean(i)) - sim_mean(i)) < 0
            rel_error_sgfnt(i) = (emu_mean(i) + abs(unctrn_mean(i)) - sim_mean(i))/sim_mean(i);
        else
            rel_error_sgfnt(i) = NaN;
        end
    else
        rel_error(i) = NaN;
        rel_error_sgfnt(i) = NaN;
    end
end

%% output results
emu_accuracy.unctrn_mean = unctrn_mean;
emu_accuracy.sim_mean = sim_mean;
emu_accuracy.emu_mean = emu_mean;
emu_accuracy.rel_error = rel_error;
emu_accuracy.rel_error_sgfnt = rel_error_sgfnt;
% check if data pass
if any(abs(rel_error_sgfnt)>threshold)
    emu_accuracy.flag = 'Warning';
else
    emu_accuracy.flag = 'Pass';
end

end

