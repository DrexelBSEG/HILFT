function data = data_process(data)
    
% Check and truncate excess data
% if length(data.Measurements) > 1441
%     data.Measurements = data.Measurements(1:1441,:);
%     data.SupvCtrlSig = data.SupvCtrlSig(1:1441,:);
%     data.SimData = data.SimData(1:1441,:);
%     if iscell(data.SimData)
%         for i = 1:length(data.SimData)
%             temp(i,1) = data.SimData{i,1};
%         end
%         data.SimData = temp;
%     end
% end
data.Measurements = reformat(data.Measurements);
data.SupvCtrlSig = reformat(data.SupvCtrlSig);
data.SimData = reformat(data.SimData);


% Process hardware data file
hdata_name = fieldnames(data.HardwareData);
hdata = eval(['data.HardwareData.' hdata_name{1}]);
[hdata_sim,delay_all] = hwdata_sent(hdata,data.Measurements);

% Extract data
% Data from SimData
data.time_step_simdata = [data.SimData.Timestep]';
data.zone_temp_sim = [data.SimData.T_z]';
data.tstat_spt_sim = [data.SimData.Tz_cspt]';

% Data from Measurements
data.time_step_sim = [data.Measurements.Timestep]';

% Data from hardware data file
data.time_step_hdata = [hdata_sim.("Simulation Time Step")];
data.wshp_power = [hdata_sim.("WSHP Power [kW]")];
data.inlet_water_temp = [hdata_sim.("Inlet Water Temp [°C]")];
data.tstat_spt_hdata = [hdata_sim.("Sim Cool SP [°C]")];
% Some old datasets do not have certain points
if ismember('Active Setpoint [°C]', hdata_sim.Properties.VariableNames)
    data.active_spt = [hdata_sim.("Active Setpoint [°C]")];
end
if ismember('Fan Speed Percent [%]', hdata_sim.Properties.VariableNames)
    fan_spd = [hdata_sim.("Fan Speed Percent [%]")];
    vdc = compressor_vdc(fan_spd, data.wshp_power, 150);
    data.comp_spd = spd_ratio(vdc);
end

% Data from MPC_DebugData
if isfield(data, 'MPC_DebugData')
    % Extract
    data.time_step_mpcdebug = [data.MPC_DebugData.Timestep]';
    data.wshp_power_pd = [data.MPC_DebugData.p_opt]'*1000;
    data.comp_spd_pd = [data.MPC_DebugData.y_opt]';
    data.inlet_water_temp_pd = [data.MPC_DebugData.T2_opt]';
    data.zone_temp_pd = [data.MPC_DebugData.Tz_opt]';
    data.wshp_power_pd_cal = predict_hp_cool_power_new(data.zone_temp_pd, data.inlet_water_temp_pd, data.comp_spd_pd); 
    % Up sample
    data.wshp_power_pd = interp1(data.time_step_mpcdebug(1:end-1), data.wshp_power_pd(1:end-1), [0:1:data.time_step_mpcdebug(end-1)]', "previous");
    data.comp_spd_pd = interp1(data.time_step_mpcdebug(1:end-1), data.comp_spd_pd(1:end-1), [0:1:data.time_step_mpcdebug(end-1)]', "previous");
    data.inlet_water_temp_pd = interp1(data.time_step_mpcdebug(1:end-1), data.inlet_water_temp_pd(1:end-1), [0:1:data.time_step_mpcdebug(end-1)]', "previous");
    data.zone_temp_pd = interp1(data.time_step_mpcdebug(1:end-1), data.zone_temp_pd(1:end-1), [0:1:data.time_step_mpcdebug(end-1)]', "previous");
    data.time_step_mpcdebug = interp1(data.time_step_mpcdebug(1:end-1), data.time_step_mpcdebug(1:end-1), [0:1:data.time_step_mpcdebug(end-1)]', "linear");
    data.time_step_mpcdebug = data.time_step_mpcdebug + 15; % Shift one time step
end

% Data from WSHP_Spt_Estimator_debug
if isfield(data, 'WSHP_Spt_Estimator_debug')
    data.time_step_spt_debug = [1:length(data.WSHP_Spt_Estimator_debug)]';
    data.time_step_spt_debug = data.time_step_spt_debug + 29;
    data.spt_est_power_opt = data.WSHP_Spt_Estimator_debug(:,2)*1000;
    data.spt_est_acc_error_opt = data.WSHP_Spt_Estimator_debug(:,1);
end

end

