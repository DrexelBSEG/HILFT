function f = EmuPlot(label,type,ts,te)
% figure
f = figure('visible','on');
f.Position = [600 400 400 220];
eval(['temp_sim = ' label '_sim;']);
eval(['temp_mea = ' label '_mea;']);
scatter(Timestep_sim(ts:te),temp_sim(ts:te),'.');hold on
scatter(Timestep_mea(ts:te),temp_mea(ts+1:te+1),'.');
xlabel ('Timestep');
xlim([0 24*60]);
xticks([0:180:24*60]);
switch type
    case 1
        ylabel('Temperature [°C]');
    case 2
        ylabel('Humidity [kg/kg]');
    case 3
        ylabel('Power [W]');
end
legend('Sim','Mea',...
    'Location','eastoutside');
title([label ' emulation'], 'Interpreter', 'none');
grid on
% save image
saveas(f,[pwd '/' report_path '/' label '.png']);
saveas(f,[pwd '/' report_path '/' label '.fig']);
img1 = Image([pwd '/' report_path '/' label '.png']);
% add image to report
add(rpt,img1);
set(f, 'Visible', 'off')
end

