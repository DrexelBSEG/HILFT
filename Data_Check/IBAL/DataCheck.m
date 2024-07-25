%% Data Checking Algorithm
clear all
clc
% user input
filename = 'Atlanta_Eff_ExtrmSum_RB_2004_TypOcc_TypBehav_NoTES_05052022_111704';
% range selection
EPlusRange = [1441:2880]; 
EPlusRange = [EPlusRange(1),EPlusRange];    %repeat the first row
% directory
par_dir = fileparts(strcat(pwd,'/DataCheck.m'));
% add to path
addpath(strcat(par_dir,'/qcfunc'));
addpath(strcat(par_dir,'/report'));
% read input
load([par_dir '/data/' filename '.mat']);
%% case setting
season = table2array(settings(1,2));
GEB_case = table2array(settings(1,3));
TES = logical(table2array(settings(1,7))); 
location = table2array(settings(1,11));
% define tou structure for shifting case
if (GEB_case == 3)
    TOU = zeros(4,1441); TOU_pday = zeros(4,239);
    switch location
        case 2
            TOU(4,:) = 0.0298;
            TOU(4,7*60+1:19*60) = 0.0409;
            TOU(4,10*60+1:16*60) = 0.113;
            TOU_pday(4,:) = 0.0298;
    end
end
%% define periods
peval_start = 7*60; peval_end = 20*60-1;    % performance evaluation period
eeval_start = 6.25*60; eeval_end = 20*60-1; % emulation evaluation period
occ_start = 6*60; occ_end = 20*60-1;        % occupied (system on) period
rt_start = 6*60+1; rt_end = 20*60;          % real time communication period
% different periods for modulating cases
if (GEB_case == 4)
    peval_start = 7*60; peval_end = 12*60-1;    % performance evaluation period
    eeval_start = 6.25*60; eeval_end = 12*60-1; % emulation evaluation period
    occ_start = 6*60; occ_end = 12*60-1;        % occupied (system on) period
    rt_start = 6*60+1; rt_end = 12*60;          % real time communication period
end
%% modify format
% trim the edges of hardware data
if ~TES
    rows_to_keep = [HardwareData.processData2.("comms_timestep") > 0 &...
        HardwareData.processData2.("comms_timestep") < 1440];
    Measurements = reformat(Measurements, 1441);
    SupvCtrlSig = reformat(SupvCtrlSig, 1441);
    SimData = reformat(SimData, 1441);
else
    rows_to_keep = [HardwareData.processData2.("comms_timestep") > -240 &...
            HardwareData.processData2.("comms_timestep") < 1440];
    Measurements = reformat(Measurements, 1680);
    SupvCtrlSig = reformat(SupvCtrlSig, 1680);
    SimData = reformat(SimData, 1441);
    Measurements = Measurements(240:1680, :);
    SupvCtrlSig = SupvCtrlSig(240:1680, :);
end
HardwareData.processData2 = HardwareData.processData2(rows_to_keep, :);
HardwareData.rawData2 = HardwareData.rawData2(rows_to_keep, :);
HardwareData.scaledData2 = HardwareData.scaledData2(rows_to_keep, :);
%% obtain hardware data rows of which measurements were sent to the simulation side
processData2 = table2struct(HardwareData.processData2);
scaledData2 = table2struct(HardwareData.scaledData2);
[scaledData2_sim,processData2_sim,delay_all] = hwdata_sent(scaledData2,processData2,Measurements);
hwdata_sent_timestep = [scaledData2_sim.timestep_sent];
%% communication delay
delay = delay_all(rt_start:rt_end);
CommonDelay.max = max(delay);
CommonDelay.mean = mean(delay);
if ((sum(delay>6)+sum(delay==-1))/length(delay)>0.05)
    CommonDelay.flag = 'Fail';
else
    CommonDelay.flag = 'Pass';
end
%% Check whether simulation data is complete
Comp_Size = 1441;%1441
if any([length(SimData)==Comp_Size length(Measurements)==Comp_Size length(OccupantMatrix)==Comp_Size length(SupvCtrlSig)==Comp_Size height(EPlusOutput)==(Comp_Size-1)*2]==0)
    if any([length(SimData)<peval_end length(Measurements)<peval_end length(OccupantMatrix)<peval_end length(SupvCtrlSig)<peval_end height(EPlusOutput)<peval_end+1440-1]==1)
        data_completeness_flag = 'Fail';
    else
        data_completeness_flag = 'Warning';
    end
else
    data_completeness_flag = 'Pass';
end
%% Check for missing hardware data
missing_data_check.processData2 = MissingDataCheck(HardwareData.processData2,30,0.01);
missing_data_check.rawData2 = MissingDataCheck(HardwareData.rawData2,30,0.01);
missing_data_check.scaledData2 = MissingDataCheck(HardwareData.scaledData2,30,0.01);
if any(contains(...
        {missing_data_check.processData2.continue_missing_flag,...
        missing_data_check.rawData2.continue_missing_flag,...
        missing_data_check.scaledData2.continue_missing_flag,...
        missing_data_check.processData2.significant_missing_flag,...
        missing_data_check.rawData2.significant_missing_flag,...
        missing_data_check.scaledData2.significant_missing_flag},...
        'Fail'))
    missing_data_check.flag = 'Fail';
else
    missing_data_check.flag = 'Pass';
end
%% Measurements
label = {'T_z1_ahu1','T_z2_ahu1','T_z1_ahu2','T_z2_ahu2',...
    'w_z1_ahu1','w_z2_ahu1','w_z1_ahu2','w_z2_ahu2',...
    'd1_ahu1','d2_ahu1','d1_ahu2','d2_ahu2',...
    'rh1_ahu1','rh2_ahu1','rh1_ahu2','rh2_ahu2',...
    'm_sup_vav1_ahu1','m_sup_vav2_ahu1','m_sup_vav1_ahu2','m_sup_vav2_ahu2',...
    'T_sup_vav1_ahu1','T_sup_vav2_ahu1','T_sup_vav1_ahu2','T_sup_vav2_ahu2',...
    'w_sup_vav1_ahu1','w_sup_vav2_ahu1','w_sup_vav1_ahu2','w_sup_vav2_ahu2'};
for i=1:length(label)
    eval([label{i} '_mea = [Measurements.' label{i} ']'';']);
end
Timestep_mea = [Measurements.Timestep]';
T_out_mea = [Measurements.T_out_emulated]';
power_ch = [Measurements.W_CHW]';
power_ahu1 = [Measurements.W_ahu1]';
power_ahu2 = [Measurements.W_ahu2]';
power_total = [Measurements.Power_HVAC]';
%% SimData
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
    eval(['T_' label{i} '_sim = [SimData.T_' label{i} ']'';']);
    eval(['w_' label{i} '_sim = [SimData.w_' label{i} ']'';']);
%     eval(['RH_' label{i} '_sim = [SimData.RH_' label{i} ']'';']);
%     eval(['w_' label{i} '_sim = omega(101325,T_' label{i} '_sim,RH_' label{i} '_sim);']);
    eval(['Tz_cspt_' label{i} ' = [SimData.Tz_cspt_' label{i} ']'';']);
    eval(['Tz_hspt_' label{i} ' = [SimData.Tz_hspt_' label{i} ']'';']);
end
Timestep_sim = [SimData.Timestep]';
T_out_sim = [SimData.T_out]'; 
RH_out_sim = [SimData.RH_out]';
%% EPlus output
T_z1_ahu1_eplus = EPlusOutput.('CONFROOM_MID_2 ZN:Zone Air Temperature [C](TimeStep)')(EPlusRange);
T_z2_ahu1_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_2 ZN:Zone Air Temperature [C](TimeStep)')(EPlusRange);
T_z1_ahu2_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_5 ZN:Zone Air Temperature [C](TimeStep)')(EPlusRange);
T_z2_ahu2_eplus = EPlusOutput.('OPENOFFICE_MID_1 ZN:Zone Air Temperature [C](TimeStep)')(EPlusRange);
w_z1_ahu1_eplus = EPlusOutput.('CONFROOM_MID_2 ZN:Zone Air Humidity Ratio [](TimeStep)')(EPlusRange);
w_z2_ahu1_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_2 ZN:Zone Air Humidity Ratio [](TimeStep)')(EPlusRange);
w_z1_ahu2_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_5 ZN:Zone Air Humidity Ratio [](TimeStep)')(EPlusRange);
w_z2_ahu2_eplus = EPlusOutput.('OPENOFFICE_MID_1 ZN:Zone Air Humidity Ratio [](TimeStep)')(EPlusRange);
m_sup_vav1_ahu1_eplus = EPlusOutput.('CONFROOM_MID_2 ZN NODE1:System Node Mass Flow Rate [kg/s](TimeS')(EPlusRange);
m_sup_vav2_ahu1_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_2 ZN NODE1:System Node Mass Flow Rate [kg/s]')(EPlusRange);
m_sup_vav1_ahu2_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_5 ZN NODE1:System Node Mass Flow Rate [kg/s]')(EPlusRange);
m_sup_vav2_ahu2_eplus = EPlusOutput.('OPENOFFICE_MID_1 ZN NODE1:System Node Mass Flow Rate [kg/s](Tim')(EPlusRange);
T_sup_vav1_ahu1_eplus = EPlusOutput.('CONFROOM_MID_2 ZN NODE1:System Node Temperature [C](TimeStep)')(EPlusRange);
T_sup_vav2_ahu1_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_2 ZN NODE1:System Node Temperature [C](TimeS')(EPlusRange);
T_sup_vav1_ahu2_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_5 ZN NODE1:System Node Temperature [C](TimeS')(EPlusRange);
T_sup_vav2_ahu2_eplus = EPlusOutput.('OPENOFFICE_MID_1 ZN NODE1:System Node Temperature [C](TimeStep)')(EPlusRange);
w_sup_vav1_ahu1_eplus = EPlusOutput.('CONFROOM_MID_2 ZN NODE1:System Node Humidity Ratio [kgWater/kgD')(EPlusRange);
w_sup_vav2_ahu1_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_2 ZN NODE1:System Node Humidity Ratio [kgWat')(EPlusRange);
w_sup_vav1_ahu2_eplus = EPlusOutput.('ENCLOSEDOFFICE_MID_5 ZN NODE1:System Node Humidity Ratio [kgWat')(EPlusRange);
w_sup_vav2_ahu2_eplus = EPlusOutput.('OPENOFFICE_MID_1 ZN NODE1:System Node Humidity Ratio [kgWater/k')(EPlusRange);
%% personal equipment usage
if ~logical(table2array(settings(1,5)))
    occ_tot = [23 2 2 10];
else
    occ_tot = [34 3 3 15];
end
% personal fan power
power_pf_z1_ahu1_eplus = EPlusOutput.('FMU_CONFROOM_MID_2 ZN_PF:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(1)*15;
power_pf_z2_ahu1_eplus = EPlusOutput.('FMU_ENCLOSEDOFFICE_MID_2 ZN_PF:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(2)*15;
power_pf_z1_ahu2_eplus = EPlusOutput.('FMU_ENCLOSEDOFFICE_MID_5 ZN_PF:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(3)*15;
power_pf_z2_ahu2_eplus = EPlusOutput.('FMU_OPENOFFICE_MID_1 ZN_PF:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(4)*15;
power_pf = power_pf_z1_ahu1_eplus + power_pf_z2_ahu1_eplus + power_pf_z1_ahu2_eplus + power_pf_z2_ahu2_eplus;
% personal fan power
power_ph_z1_ahu1_eplus = EPlusOutput.('FMU_CONFROOM_MID_2 ZN_PH:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(1)*1200;
power_ph_z2_ahu1_eplus = EPlusOutput.('FMU_ENCLOSEDOFFICE_MID_2 ZN_PH:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(2)*1200;
power_ph_z1_ahu2_eplus = EPlusOutput.('FMU_ENCLOSEDOFFICE_MID_5 ZN_PH:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(3)*1200;
power_ph_z2_ahu2_eplus = EPlusOutput.('FMU_OPENOFFICE_MID_1 ZN_PH:Schedule Value [](TimeStep)')(EPlusRange)*occ_tot(4)*1200;
power_ph = power_ph_z1_ahu1_eplus + power_ph_z2_ahu1_eplus + power_ph_z1_ahu2_eplus + power_ph_z2_ahu2_eplus;
%% Supervisory control signals
P_sp_ahu1 = [SupvCtrlSig.P_sp_ahu1]';
P_sp_ahu2 = [SupvCtrlSig.P_sp_ahu2]';
T_SA_ahu1 = [SupvCtrlSig.T_SA_ahu1]';
T_SA_ahu2 = [SupvCtrlSig.T_SA_ahu2]';
T_chwst = [SupvCtrlSig.T_chwst]';
DP_slSP = [SupvCtrlSig.DP_slSP]';
%% Minute by minute measurements from hardware data
RH_z1_ahu1_mea = [scaledData2_sim.zs3_rh]';
RH_z2_ahu1_mea = [scaledData2_sim.zs4_rh]';
RH_z1_ahu2_mea = [scaledData2_sim.zs1_rh]';
RH_z2_ahu2_mea = [scaledData2_sim.zs2_rh]';
RH_sup_vav1_ahu1_mea = [scaledData2_sim.ahu1_rh_down]';
RH_sup_vav2_ahu1_mea = [scaledData2_sim.ahu1_rh_down]';
RH_sup_vav1_ahu2_mea = [scaledData2_sim.ahu2_rh_down]';
RH_sup_vav2_ahu2_mea = [scaledData2_sim.ahu2_rh_down]';
RH_out_mea = [processData2_sim.oau_w_rh_pv_per]'; 
vlv_steamer_z1_ahu1_mea = [scaledData2_sim.v16_pos_c]';
vlv_steamer_z2_ahu1_mea = [scaledData2_sim.v17_pos_c]';
vlv_steamer_z1_ahu2_mea = [scaledData2_sim.v14_pos_c]';
vlv_steamer_z2_ahu2_mea = [scaledData2_sim.v15_pos_c]';
P_sp_ahu1_mea = [processData2_sim.ahu1_fan_pv_inh2o]'*248.84; % inwg to Pa
P_sp_ahu2_mea = [processData2_sim.ahu2_fan_pv_inh2o]'*248.84; % inwg to Pa
T_SA_ahu1_mea = ([scaledData2_sim.ahu1_out_rtd]'-32)/1.8; % F to C
T_SA_ahu2_mea = ([scaledData2_sim.ahu2_out_rtd]'-32)/1.8; % F to C
DP_slSP_mea = [scaledData2_sim.pump3_dp]'*6.89476; % psi to kPa
ch1_on = [scaledData2_sim.ch1_on];
ch2_on = [scaledData2_sim.ch2_on];
T_ch1 = ([scaledData2_sim.ch1_e_out_rtd]'-32)/1.8; % F to C 
T_ch2 = ([scaledData2_sim.ch2_e_out_rtd]'-32)/1.8; % F to C 
CFMspt_vav1_ahu1 = [processData2_sim.vav3_d_sp]';
CFMspt_vav2_ahu1 = [processData2_sim.vav4_d_sp]';
CFMspt_vav1_ahu2 = [processData2_sim.vav1_d_sp]';
CFMspt_vav2_ahu2 = [processData2_sim.vav2_d_sp]';
ts_meter = [scaledData2_sim.ts_meter]';
%% emulated load calculated from measurements
for i=1:length(Measurements)
    [Qsen_z1_ahu1_mea(i,1),Qlat_z1_ahu1_mea(i,1)] = ...
        AirStreamLoad(T_sup_vav1_ahu1_mea(i),T_z1_ahu1_mea(i),w_sup_vav1_ahu1_mea(i),w_z1_ahu1_mea(i),m_sup_vav1_ahu1_mea(i));
    [Qsen_z2_ahu1_mea(i,1),Qlat_z2_ahu1_mea(i,1)] = ...
        AirStreamLoad(T_sup_vav2_ahu1_mea(i),T_z2_ahu1_mea(i),w_sup_vav2_ahu1_mea(i),w_z2_ahu1_mea(i),m_sup_vav2_ahu1_mea(i)); 
    [Qsen_z1_ahu2_mea(i,1),Qlat_z1_ahu2_mea(i,1)] = ...
        AirStreamLoad(T_sup_vav1_ahu2_mea(i),T_z1_ahu2_mea(i),w_sup_vav1_ahu2_mea(i),w_z1_ahu2_mea(i),m_sup_vav1_ahu2_mea(i));
    [Qsen_z2_ahu2_mea(i,1),Qlat_z2_ahu2_mea(i,1)] = ...
        AirStreamLoad(T_sup_vav2_ahu2_mea(i),T_z2_ahu2_mea(i),w_sup_vav2_ahu2_mea(i),w_z2_ahu2_mea(i),m_sup_vav2_ahu2_mea(i));
end
%% simulated load calculated from EPlus
for i=1:length(SimData)
    [Qsen_z1_ahu1_sim(i,1),Qlat_z1_ahu1_sim(i,1)] = ...
        AirStreamLoad(T_sup_vav1_ahu1_eplus(i),T_z1_ahu1_eplus(i),...
                      w_sup_vav1_ahu1_eplus(i),w_z1_ahu1_eplus(i),...
                      m_sup_vav1_ahu1_eplus(i));
    [Qsen_z2_ahu1_sim(i,1),Qlat_z2_ahu1_sim(i,1)] = ...
        AirStreamLoad(T_sup_vav2_ahu1_eplus(i),T_z2_ahu1_eplus(i),...
                      w_sup_vav2_ahu1_eplus(i),w_z2_ahu1_eplus(i),...
                      m_sup_vav2_ahu1_eplus(i)); 
    [Qsen_z1_ahu2_sim(i,1),Qlat_z1_ahu2_sim(i,1)] = ...
        AirStreamLoad(T_sup_vav1_ahu2_eplus(i),T_z1_ahu2_eplus(i),...
                      w_sup_vav1_ahu2_eplus(i),w_z1_ahu2_eplus(i),...
                      m_sup_vav1_ahu2_eplus(i));
    [Qsen_z2_ahu2_sim(i,1),Qlat_z2_ahu2_sim(i,1)] = ...
        AirStreamLoad(T_sup_vav2_ahu2_eplus(i),T_z2_ahu2_eplus(i),...
                      w_sup_vav2_ahu2_eplus(i),w_z2_ahu2_eplus(i),...
                      m_sup_vav2_ahu2_eplus(i));
end
%% obtain power
% water side
ch1_power = [scaledData2_sim.ch1_power];
ch2_power = [scaledData2_sim.ch2_power];
pump1_power = [scaledData2_sim.pump1_power];
pump2_power = [scaledData2_sim.pump2_power];
pump3_power = [scaledData2_sim.pump3_power];
pump4_power = [scaledData2_sim.pump4_power];
waterside_power = ch1_power + ch2_power + pump1_power + pump2_power + pump3_power + pump4_power;
% ahu1
ahu1_fan_power = [scaledData2_sim.ahu1_fan_power];
vav3_heat_power = [scaledData2_sim.vav3_heat_power];
vav4_heat_power = [scaledData2_sim.vav4_heat_power];
airside_ahu1_power = ahu1_fan_power + vav3_heat_power + vav4_heat_power;
% ahu2
ahu2_fan_power = [scaledData2_sim.ahu2_fan_power];
vav1_heat_power = [scaledData2_sim.vav1_heat_power];
vav2_heat_power = [scaledData2_sim.vav2_heat_power];
airside_ahu2_power = ahu1_fan_power + vav1_heat_power + vav2_heat_power;
%% obtain min-by-min hardware data of the previous day if TES is tested
if TES
    [scaledData2_pday,processData2_pday,~] = hwdata_per_min(scaledData2,processData2,-239,-1);
    % ice tank inventory
    ts_meter_pday = [scaledData2_pday.ts_meter]';
    % water side power
    label = {'ch1_power','ch2_power',...
        'pump1_power','pump2_power',...
        'pump3_power','pump4_power'};
    % previous day data
    for i = 1:length(label)
        eval([label{i} '_pday = [scaledData2_pday.' label{i} '];']);
    end
    % append test day data
    waterside_power_all = 0;
    for i = 1:length(label)
        eval([label{i} '_all = [' label{i} '_pday,' label{i} '];']);
        eval(['waterside_power_all = waterside_power_all + ' label{i} '_all;']);
    end 
    % ahu1 power
    label = {'ahu1_fan_power','vav3_heat_power','vav4_heat_power'};
    % previous day data
    for i = 1:length(label)
        eval([label{i} '_pday = [scaledData2_pday.' label{i} '];']);
    end
    % append test day data
    airside_ahu1_power_all = 0;
    for i = 1:length(label)
        eval([label{i} '_all = [' label{i} '_pday,' label{i} '];']);
        eval(['airside_ahu1_power_all = airside_ahu1_power_all + ' label{i} '_all;']);
    end
    % ahu1 power
    label = {'ahu2_fan_power','vav1_heat_power','vav2_heat_power'};
    % previous day data
    for i = 1:length(label)
        eval([label{i} '_pday = [scaledData2_pday.' label{i} '];']);
    end
    % append test day data
    airside_ahu2_power_all = 0;
    for i = 1:length(label)
        eval([label{i} '_all = [' label{i} '_pday,' label{i} '];']);
        eval(['airside_ahu2_power_all = airside_ahu2_power_all + ' label{i} '_all;']);
    end
    % total power (w/ personal fan and personal heater)
    power_all = waterside_power_all + airside_ahu1_power_all + airside_ahu2_power_all + ...
        [repmat([0],1,239),power_pf'] + [repmat([0],1,239),power_ph'];
end
%% Electricity price
if TES
    TOU_all = [TOU_pday,TOU];
    % initialize accumulated price array
    price_acc = zeros(1,1441+239);
    price_acc(1) = power_all(1)*TOU_all(season,1)/60;
    for i=2:length(TOU_all)
        price_acc(i) = price_acc(i-1) + (power_all(i)/1000)*TOU_all(season,i)/60;
    end
end

%% Uncertainty
for i=1:1441
%     uQlat_z1_ahu1(i,1) = uQLatent_mDot(m_sup_vav1_ahu1_mea(i),...
%                                      RH_z1_ahu1_sim(i),T_z1_ahu1_sim(i)*1.8+32,...
%                                      RH_sup_vav1_ahu1_mea(i),T_sup_vav1_ahu1_mea(i),...
%                                      w_z1_ahu1_eplus(i),w_sup_vav1_ahu1_mea(i),...
%                                      vlv_steamer_z1_ahu1_mea(i));
%     uQlat_z2_ahu1(i,1) = uQLatent_mDot(m_sup_vav2_ahu1_mea(i),...
%                                      RH_z2_ahu1_sim(i),T_z2_ahu1_sim(i)*1.8+32,...
%                                      RH_sup_vav2_ahu1_mea(i),T_sup_vav2_ahu1_mea(i),...
%                                      w_z2_ahu1_eplus(i),w_sup_vav2_ahu1_mea(i),...
%                                      vlv_steamer_z2_ahu1_mea(i));
%     uQlat_z1_ahu2(i,1) = uQLatent_mDot(m_sup_vav1_ahu2_mea(i),...
%                                      RH_z1_ahu2_sim(i),T_z1_ahu2_sim(i)*1.8+32,...
%                                      RH_sup_vav1_ahu2_mea(i),T_sup_vav1_ahu2_mea(i),...
%                                      w_z1_ahu2_eplus(i),w_sup_vav1_ahu2_mea(i),...
%                                      vlv_steamer_z1_ahu2_mea(i));
%     uQlat_z2_ahu2(i,1) = uQLatent_mDot(m_sup_vav2_ahu2_mea(i),...
%                                      RH_z2_ahu2_sim(i),T_z2_ahu2_sim(i)*1.8+32,...
%                                      RH_sup_vav2_ahu2_mea(i),T_sup_vav2_ahu2_mea(i),...
%                                      w_z2_ahu2_eplus(i),w_sup_vav2_ahu2_mea(i),...
%                                      vlv_steamer_z2_ahu2_mea(i));
end
%% FR performance
if (GEB_case == 4)
    % rows of data associated with FR period
    ahu1_fr_row = find(HardwareData.processData2.ahu1_fr_frMode==1);
    ahu2_fr_row = find(HardwareData.processData2.ahu2_fr_frMode==1);
    if ~isequal(ahu1_fr_row,ahu2_fr_row)
        disp('Inconsistent FR periods.');
    end    
    % ahu1 fr score
    ahu1_fr_sp_w = HardwareData.processData2.ahu1_fr_sp_w(ahu1_fr_row);
    ahu1_fr_pv_w = HardwareData.processData2.ahu1_fr_pv_w(ahu1_fr_row);
    ahu1_fr_basePower = HardwareData.processData2.ahu1_fr_basePower(ahu1_fr_row);
    ahu1_fr_dPower = HardwareData.processData2.ahu1_fr_dPower(ahu1_fr_row);
    ahu1_fr_Powerset = ahu1_fr_basePower + ahu1_fr_sp_w;
    ahu1_fr_Power = ahu1_fr_basePower + ahu1_fr_pv_w;
    ahu1_fr_score = Function_Performance_score(ahu1_fr_Powerset,ahu1_fr_Power,ahu1_fr_basePower,ahu1_fr_dPower(1));
    ahu1_power_ext = HardwareData.scaledData2.ahu1_fan_power([ahu1_fr_row(1)-30:ahu1_fr_row(end)+30]);
    % ahu2 fr score
    ahu2_fr_sp_w = HardwareData.processData2.ahu2_fr_sp_w(ahu2_fr_row);
    ahu2_fr_pv_w = HardwareData.processData2.ahu2_fr_pv_w(ahu2_fr_row);
    ahu2_fr_basePower = HardwareData.processData2.ahu2_fr_basePower(ahu2_fr_row);
    ahu2_fr_dPower = HardwareData.processData2.ahu2_fr_dPower(ahu2_fr_row);
	ahu2_fr_Powerset = ahu2_fr_basePower + ahu2_fr_sp_w;
    ahu2_fr_Power = ahu2_fr_basePower + ahu2_fr_pv_w;
    ahu2_fr_score = Function_Performance_score(ahu2_fr_Powerset,ahu2_fr_Power,ahu2_fr_basePower,ahu2_fr_dPower(1));    
    ahu2_power_ext = HardwareData.scaledData2.ahu2_fan_power([ahu2_fr_row(1)-30:ahu2_fr_row(end)+30]);
    % pass/fail
    if (ahu1_fr_score(4)<0.75 || ahu2_fr_score(4)<0.75)
        FR_flag = 'Fail';
    else
        FR_flag = 'Pass';
    end
end
%% Emulation accuracy
% tolerance
Tz_emu_etol = 0.56;
RH_emu_etol = 5;
w_emu_etol = 0.001;
RH_out_emu_etol = 10;
RH_out_emu_rtol = 0.1;
Qsen_emu_etol = 150;
Qlat_emu_etol = 300;
% accuracy
emu_accuracy.T_z1_ahu1 = EmuAccuracy(T_z1_ahu1_eplus(eeval_start:eeval_end),T_z1_ahu1_mea(eeval_start+1:eeval_end+1),Tz_emu_etol);
emu_accuracy.T_z2_ahu1 = EmuAccuracy(T_z2_ahu1_eplus(eeval_start:eeval_end),T_z2_ahu1_mea(eeval_start+1:eeval_end+1),Tz_emu_etol);
emu_accuracy.T_z1_ahu2 = EmuAccuracy(T_z1_ahu2_eplus(eeval_start:eeval_end),T_z1_ahu2_mea(eeval_start+1:eeval_end+1),Tz_emu_etol);
emu_accuracy.T_z2_ahu2 = EmuAccuracy(T_z2_ahu2_eplus(eeval_start:eeval_end),T_z2_ahu2_mea(eeval_start+1:eeval_end+1),Tz_emu_etol);
emu_accuracy.T_out = EmuAccuracy(T_out_sim(eeval_start:eeval_end),T_out_mea(eeval_start+1:eeval_end+1),Tz_emu_etol);
% emu_accuracy.RH_z1_ahu1 = EmuAccuracy(RH_z1_ahu1_sim(eeval_start:eeval_end),RH_z1_ahu1_mea(eeval_start+1:eeval_end+1),RH_emu_etol);
% emu_accuracy.RH_z2_ahu1 = EmuAccuracy(RH_z2_ahu1_sim(eeval_start:eeval_end),RH_z2_ahu1_mea(eeval_start+1:eeval_end+1),RH_emu_etol);
% emu_accuracy.RH_z1_ahu2 = EmuAccuracy(RH_z1_ahu2_sim(eeval_start:eeval_end),RH_z1_ahu2_mea(eeval_start+1:eeval_end+1),RH_emu_etol);
% emu_accuracy.RH_z2_ahu2 = EmuAccuracy(RH_z2_ahu2_sim(eeval_start:eeval_end),RH_z2_ahu2_mea(eeval_start+1:eeval_end+1),RH_emu_etol);
emu_accuracy.RH_out = EmuAccuracy(RH_out_sim(eeval_start:eeval_end),RH_out_mea(eeval_start+1:eeval_end+1),RH_emu_etol);
emu_accuracy.RH_out_rate = EmuAccuracy2(RH_out_sim(eeval_start:eeval_end),RH_out_mea(eeval_start+1:eeval_end+1),RH_out_emu_etol,RH_out_emu_rtol);
emu_accuracy.w_z1_ahu1 = EmuAccuracy(w_z1_ahu1_eplus(eeval_start:eeval_end),w_z1_ahu1_mea(eeval_start+1:eeval_end+1),w_emu_etol);
emu_accuracy.w_z2_ahu1 = EmuAccuracy(w_z2_ahu1_eplus(eeval_start:eeval_end),w_z2_ahu1_mea(eeval_start+1:eeval_end+1),w_emu_etol);
emu_accuracy.w_z1_ahu2 = EmuAccuracy(w_z1_ahu2_eplus(eeval_start:eeval_end),w_z1_ahu2_mea(eeval_start+1:eeval_end+1),w_emu_etol);
emu_accuracy.w_z2_ahu2 = EmuAccuracy(w_z2_ahu2_eplus(eeval_start:eeval_end),w_z2_ahu2_mea(eeval_start+1:eeval_end+1),w_emu_etol);
emu_accuracy.Qsen_z1_ahu1 = EmuAccuracy(-Qsen_z1_ahu1_sim(eeval_start+1:eeval_end+1),-Qsen_z1_ahu1_mea(eeval_start:eeval_end),Qsen_emu_etol);
emu_accuracy.Qsen_z2_ahu1 = EmuAccuracy(-Qsen_z2_ahu1_sim(eeval_start+1:eeval_end+1),-Qsen_z2_ahu1_mea(eeval_start:eeval_end),Qsen_emu_etol);
emu_accuracy.Qsen_z1_ahu2 = EmuAccuracy(-Qsen_z1_ahu2_sim(eeval_start+1:eeval_end+1),-Qsen_z1_ahu2_mea(eeval_start:eeval_end),Qsen_emu_etol);
emu_accuracy.Qsen_z2_ahu2 = EmuAccuracy(-Qsen_z2_ahu2_sim(eeval_start+1:eeval_end+1),-Qsen_z2_ahu2_mea(eeval_start:eeval_end),Qsen_emu_etol);
emu_accuracy.Qlat_z1_ahu1 = EmuAccuracy(-Qlat_z1_ahu1_sim(eeval_start+1:eeval_end+1),-Qlat_z1_ahu1_mea(eeval_start:eeval_end),Qlat_emu_etol);
emu_accuracy.Qlat_z2_ahu1 = EmuAccuracy(-Qlat_z2_ahu1_sim(eeval_start+1:eeval_end+1),-Qlat_z2_ahu1_mea(eeval_start:eeval_end),Qlat_emu_etol);
emu_accuracy.Qlat_z1_ahu2 = EmuAccuracy(-Qlat_z1_ahu2_sim(eeval_start+1:eeval_end+1),-Qlat_z1_ahu2_mea(eeval_start:eeval_end),Qlat_emu_etol);
emu_accuracy.Qlat_z2_ahu2 = EmuAccuracy(-Qlat_z2_ahu2_sim(eeval_start+1:eeval_end+1),-Qlat_z2_ahu2_mea(eeval_start:eeval_end),Qlat_emu_etol);
% set NA FR_flag for non FR cases
if (GEB_case ~= 4)
    FR_flag = 'NA';
end
% overall
if any(contains(...
        {emu_accuracy.T_z1_ahu1.flag,...
        emu_accuracy.T_z2_ahu1.flag,...
        emu_accuracy.T_z1_ahu2.flag,...
        emu_accuracy.T_z2_ahu2.flag,...
        emu_accuracy.w_z1_ahu1.flag,...
        emu_accuracy.w_z2_ahu1.flag,...
        emu_accuracy.w_z1_ahu2.flag,...
        emu_accuracy.w_z2_ahu2.flag,... 
        emu_accuracy.T_out.flag,...
        emu_accuracy.RH_out_rate.flag,...
        emu_accuracy.Qsen_z1_ahu1.flag,...
        emu_accuracy.Qsen_z2_ahu1.flag,...
        emu_accuracy.Qsen_z1_ahu2.flag,...
        emu_accuracy.Qsen_z2_ahu2.flag,...
        emu_accuracy.Qlat_z1_ahu1.flag,...
        emu_accuracy.Qlat_z2_ahu1.flag,...
        emu_accuracy.Qlat_z1_ahu2.flag,...
        emu_accuracy.Qlat_z2_ahu2.flag,...
        FR_flag},...
        'Fail'))
    emu_accuracy.flag = 'Fail';
else
    emu_accuracy.flag = 'Pass';
end
%% System performance
% threshold
Tz_e = 1;
P_sp_e = 25;
T_SA_e = 1;
T_chwst_e = 0.5;
DP_slSP_e = 13.8;
% zone temperature
sys_performance.T_z1_ahu1 = DualSptCmpr(T_z1_ahu1_eplus,Tz_cspt_z1_ahu1,Tz_hspt_z1_ahu1,[peval_start:peval_end],Tz_e,60);
sys_performance.T_z2_ahu1 = DualSptCmpr(T_z2_ahu1_eplus,Tz_cspt_z2_ahu1,Tz_hspt_z2_ahu1,[peval_start:peval_end],Tz_e,60);
sys_performance.T_z1_ahu2 = DualSptCmpr(T_z1_ahu2_eplus,Tz_cspt_z1_ahu2,Tz_hspt_z1_ahu2,[peval_start:peval_end],Tz_e,60);
sys_performance.T_z2_ahu2 = DualSptCmpr(T_z2_ahu2_eplus,Tz_cspt_z2_ahu2,Tz_hspt_z2_ahu2,[peval_start:peval_end],Tz_e,60);
% AHU static pressure
sys_performance.P_sp_ahu1 = SnglSptCmprWarn(P_sp_ahu1_mea(peval_start:peval_end),P_sp_ahu1(peval_start:peval_end,2),-1,P_sp_e,60);
sys_performance.P_sp_ahu2 = SnglSptCmprWarn(P_sp_ahu2_mea(peval_start:peval_end),P_sp_ahu2(peval_start:peval_end,2),-1,P_sp_e,60);
% AHU supply air temperature
sys_performance.T_SA_ahu1 = SnglSptCmprWarn(T_SA_ahu1_mea(peval_start:peval_end),T_SA_ahu1(peval_start:peval_end,2),1,T_SA_e,60);
sys_performance.T_SA_ahu2 = SnglSptCmprWarn(T_SA_ahu2_mea(peval_start:peval_end),T_SA_ahu2(peval_start:peval_end,2),1,T_SA_e,60);
% chilled water temperature
sys_performance.T_ch1 = SnglSptCmprChw(T_ch1(peval_start:peval_end),T_chwst(peval_start:peval_end,2),1,T_chwst_e,60,ch1_on(peval_start:peval_end),ch1_power(peval_start:peval_end));
sys_performance.T_ch2 = SnglSptCmprChw(T_ch2(peval_start:peval_end),T_chwst(peval_start:peval_end,2),1,T_chwst_e,60,ch2_on(peval_start:peval_end),ch2_power(peval_start:peval_end));
% chilled water secondary loop differential pressure
sys_performance.DP_slSP = SnglSptCmprChw(DP_slSP_mea(peval_start:peval_end),DP_slSP(peval_start:peval_end,2),-1,DP_slSP_e,60,ch1_on,ch1_power);
% chilled water reset
if any(contains(...
        {sys_performance.T_z1_ahu1.flag,...
        sys_performance.T_z2_ahu1.flag,...
        sys_performance.T_z1_ahu2.flag,...
        sys_performance.T_z2_ahu2.flag,...
%         sys_performance.T_SA_ahu1.flag,...
%         sys_performance.T_SA_ahu2.flag,...
        },'Fail'))
    if contains(sys_performance.T_SA_ahu1.flag,'Warning') && ...
            any(contains({sys_performance.T_z1_ahu1.flag,...
            sys_performance.T_z2_ahu1.flag},'Fail'))
        sys_performance.T_SA_ahu1.flag = 'Fail';
    end
    if contains(sys_performance.T_SA_ahu2.flag,'Warning') && ...
            any(contains({sys_performance.T_z1_ahu2.flag,...
            sys_performance.T_z2_ahu2.flag},'Fail'))
        sys_performance.T_SA_ahu2.flag = 'Fail';
    end
    if contains(sys_performance.P_sp_ahu1.flag,'Warning') && ...
            any(contains({sys_performance.T_z1_ahu1.flag,...
            sys_performance.T_z2_ahu1.flag},'Fail'))
        sys_performance.P_sp_ahu1.flag = 'Fail';
    end
    if contains(sys_performance.P_sp_ahu2.flag,'Warning') && ...
            any(contains({sys_performance.T_z1_ahu2.flag,...
            sys_performance.T_z2_ahu2.flag},'Fail'))
        sys_performance.P_sp_ahu2.flag = 'Fail';
    end       
    if contains(sys_performance.T_ch1.flag,'Warning')
        sys_performance.T_ch1.flag = 'Fail';
    end
    if contains(sys_performance.T_ch2.flag,'Warning')
        sys_performance.T_ch2.flag = 'Fail';
    end
    if contains(sys_performance.DP_slSP.flag,'Warning')
        sys_performance.DP_slSP.flag = 'Fail';
    end     
end
% overall 
if any(contains(...
        {sys_performance.T_z1_ahu1.flag,...
        sys_performance.T_z2_ahu1.flag,...
        sys_performance.T_z1_ahu2.flag,...
        sys_performance.T_z2_ahu2.flag,...
        sys_performance.P_sp_ahu1.flag,...
        sys_performance.P_sp_ahu2.flag,...
        sys_performance.T_SA_ahu1.flag,...
        sys_performance.T_SA_ahu2.flag,...
        sys_performance.T_ch1.flag,...
        sys_performance.T_ch2.flag,...
        sys_performance.DP_slSP.flag},...
        'Fail'))
    sys_performance.flag = 'Fail';
else
    sys_performance.flag = 'Pass';
end
%% Summary
if any(contains(...
        {CommonDelay.flag,...
        data_completeness_flag,...
        missing_data_check.flag,...
        emu_accuracy.flag,...
        sys_performance.flag},...
        'Fail'))
    Result = 'Fail';
else
    Result = 'Pass';
end
%% report
% convert time in min to hh:mm format for reporting
[peval_start_hhmm] = min2hhmm(peval_start);
[peval_end_hhmm] = min2hhmm(peval_end);
[eeval_start_hhmm] = min2hhmm(eeval_start);
[eeval_end_hhmm] = min2hhmm(eeval_end);
[occ_start_hhmm] = min2hhmm(occ_start);
[occ_end_hhmm] = min2hhmm(occ_end);
[rt_start_hhmm] = min2hhmm(rt_start);
[rt_end_hhmm] = min2hhmm(rt_end);
peval_hhmm = [peval_start_hhmm ' - ' peval_end_hhmm];
eeval_hhmm = [eeval_start_hhmm ' - ' eeval_end_hhmm];
occ_hhmm = [occ_start_hhmm ' - ' occ_end_hhmm];
rt_hhmm = [rt_start_hhmm '-' rt_end_hhmm];
% Append data checking result to the filename
filename = [filename '_' Result];   
% where to save the report
report_path = ['report/' filename];
% initialize report
import mlreportgen.report.*
import mlreportgen.dom.*
rpt = Report([pwd '/' report_path '/' filename],"pdf"); 
if isfolder(report_path)
    delete([report_path '/*']);
else
    mkdir(report_path);
end
% ------Title------------------------------
tp = TitlePage();
tp.Title = Text(filename);
tp.Title.FontSize = '15pt';
tp.Subtitle = Text(Result);
if contains(Result,'Fail')
    tp.Subtitle.Color = "red";
else
    tp.Subtitle.Color = "green";
end
tp.PubDate = date();
tp.Author = [];
add(rpt,tp);
% ------Communication delay--------------------------
add(rpt,Heading(1,['Commuication delay: ' CommonDelay.flag ' (evaluated period: ' rt_hhmm ')']));
add(rpt,...
    {['Maximum delay: ' num2str(CommonDelay.max*10) ' sec'],... 
    ['Average delay: ' num2str(CommonDelay.mean*10) ' sec']}); 
% ------Simulation data completeness--------------------------
add(rpt,Heading(1,['Simulation data completeness: ', data_completeness_flag])); 
add(rpt,...
    {['SimData: ' num2str(length(SimData))],... 
    ['Measurements: ' num2str(length(Measurements))],...
    ['OccupantMatrix: ' num2str(length(OccupantMatrix))],...
    ['SupvCtrlSig: ' num2str(length(SupvCtrlSig))],...
    ['EPlusOutput: ' num2str(height(EPlusOutput))]});
% ------Hardware Missing data--------------------------
add(rpt,Heading(1,['Hardware missing data: ' missing_data_check.flag])); 
add(rpt,...
    {['processData2 random missing: ' num2str(missing_data_check.processData2.significant_missing_flag)],... 
    ['processData2 continuous missing: ' num2str(missing_data_check.processData2.continue_missing_flag)],...
    ['scaledData2 random missing: ' num2str(missing_data_check.scaledData2.significant_missing_flag)],...
    ['scaledData2 continuous missing: ' num2str(missing_data_check.scaledData2.continue_missing_flag)],...
    ['rawData2 random missing: ' num2str(missing_data_check.rawData2.significant_missing_flag)],...
    ['rawData2 continuous missing: ' num2str(missing_data_check.rawData2.continue_missing_flag)]});
% ------FR score--------------------------
if (GEB_case==4)
    add(rpt,Heading(1,['Frequency regulation: ' FR_flag ' (evaluated period: 8:00-8:40)'])); 
    add(rpt,...
    {['AHU1 S = ' num2str(ahu1_fr_score(4))],...
    ['AHU1 Sc = ' num2str(ahu1_fr_score(1))],...
    ['AHU1 Sd = ' num2str(ahu1_fr_score(2))],...
    ['AHU1 Sp = ' num2str(ahu1_fr_score(3))],...
    ['AHU2 S = ' num2str(ahu2_fr_score(4))],...
    ['AHU2 Sc = ' num2str(ahu2_fr_score(1))],...
    ['AHU2 Sd = ' num2str(ahu2_fr_score(2))],...
    ['AHU2 Sp = ' num2str(ahu2_fr_score(3))]}); 
end
% ------Emulation accuracy--------------------------
add(rpt,Heading(1,['Emulation accuracy: ' emu_accuracy.flag ' (evaluated period: ' eeval_hhmm ')'])); 
% Zone Temperature
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
	add(rpt,Heading(2,[label{i} ' temperature emulation accuracy: ' eval(['emu_accuracy.T_' label{i} '.flag'])]));
    add(rpt,...
        {['Criteria: RMSE <= ' num2str(Tz_emu_etol) ' °C'],...
        ['RMSE: ' num2str(eval(['emu_accuracy.T_' label{i} '.rmse'])) ' °C'],... 
        ['NRMSE: ' num2str(eval(['emu_accuracy.T_' label{i} '.nrmse']))],...
        ['Simulated Mean: ' num2str(eval(['emu_accuracy.T_' label{i} '.sim_mean'])) ' °C'],...
        ['Emulated Mean: ' num2str(eval(['emu_accuracy.T_' label{i} '.emu_mean'])) ' °C']});     
end
% Outdoor Air Temperature
add(rpt,Heading(2,['Outdoor air temperature emulation accuracy: ' emu_accuracy.T_out.flag])); 
add(rpt,...
    {['Criteria: RMSE <= ' num2str(Tz_emu_etol) ' °C'],...
    ['RMSE: ' num2str(emu_accuracy.T_out.rmse) ' °C'],... 
    ['NRMSE: ' num2str(emu_accuracy.T_out.nrmse)],...
    ['Simulated Mean: ' num2str(emu_accuracy.T_out.sim_mean) ' °C'],...
    ['Emulated Mean: ' num2str(emu_accuracy.T_out.emu_mean) ' °C']}); 
% humidity ratio emulation
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
	add(rpt,Heading(2,[label{i} ' humidity ratio emulation accuracy: ' eval(['emu_accuracy.w_' label{i} '.flag'])]));
    add(rpt,...
        {['Criteria: RMSE <= ' num2str(w_emu_etol) ' kg/kg'],...
        ['RMSE: ' num2str(eval(['emu_accuracy.w_' label{i} '.rmse'])) ' kg/kg'],... 
        ['NRMSE: ' num2str(eval(['emu_accuracy.w_' label{i} '.nrmse']))],...
        ['Simulated Mean: ' num2str(eval(['emu_accuracy.w_' label{i} '.sim_mean'])) ' kg/kg'],...
        ['Emulated Mean: ' num2str(eval(['emu_accuracy.w_' label{i} '.emu_mean'])) ' kg/kg']});     
end
% Outdoor Air Relative Humidity
add(rpt,Heading(2,['Outdoor air relative humidity accuracy: ' emu_accuracy.RH_out_rate.flag])); 
add(rpt,...
    {['Criteria: % of timesteps with emulated relative humidity outside the ' ...
    num2str(RH_out_emu_etol) '%RH range of the simulated relative humidity <= ' num2str(RH_out_emu_rtol*100) '%'],...
    ['Result: % of timesteps with emulated relative humidity outside the ' ...
    num2str(RH_out_emu_etol) '%RH range of the simulated relative humidity = ' num2str(emu_accuracy.RH_out_rate.rate*100) '%'],...
    ['RMSE: ' num2str(emu_accuracy.RH_out.rmse) ' %RH'],... 
    ['NRMSE: ' num2str(emu_accuracy.RH_out.nrmse)],...
    ['Simulated Mean: ' num2str(emu_accuracy.RH_out.sim_mean) ' %RH'],...
    ['Emulated Mean: ' num2str(emu_accuracy.RH_out.emu_mean) ' %RH']}); 
% Zone sensible load emulation
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
	add(rpt,Heading(2,[label{i} ' sensible load emulation accuracy: ' eval(['emu_accuracy.Qsen_' label{i} '.flag'])]));
    add(rpt,...
        {['RMSE: ' num2str(eval(['emu_accuracy.Qsen_' label{i} '.rmse'])) ' W'],... 
        ['NRMSE: ' num2str(eval(['emu_accuracy.Qsen_' label{i} '.nrmse']))],...
        ['Simulated Mean: ' num2str(eval(['emu_accuracy.Qsen_' label{i} '.sim_mean'])) ' W'],...
        ['Emulated Mean: ' num2str(eval(['emu_accuracy.Qsen_' label{i} '.emu_mean'])) ' W']});     
end
% Zone latent load emulation
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
	add(rpt,Heading(2,[label{i} ' latent load emulation accuracy: ' eval(['emu_accuracy.Qlat_' label{i} '.flag'])]));
    add(rpt,...
        {['RMSE: ' num2str(eval(['emu_accuracy.Qlat_' label{i} '.rmse'])) ' W'],... 
        ['NRMSE: ' num2str(eval(['emu_accuracy.Qlat_' label{i} '.nrmse']))],...
        ['Simulated Mean: ' num2str(eval(['emu_accuracy.Qlat_' label{i} '.sim_mean'])) ' W'],...
        ['Emulated Mean: ' num2str(eval(['emu_accuracy.Qlat_' label{i} '.emu_mean'])) ' W']});     
end
% ------System performance--------------------------
add(rpt,Heading(1,['System performance: ' sys_performance.flag ' (evaluated period: ' peval_hhmm ')'])); 
% Zone temperature control
add(rpt,Heading(2,['Z1AHU1(Zn3) zone temperature control: ' sys_performance.T_z1_ahu1.flag])); 
add(rpt,...
    {['Zone temperature is ' num2str(Tz_e) ' °C higher than the setpoint for ' num2str(sys_performance.T_z1_ahu1.time_high) ' timesteps'],... 
    ['Zone temperature is ' num2str(Tz_e) ' °C lower than the setpoint for ' num2str(sys_performance.T_z1_ahu1.time_low) ' timesteps']}); 
add(rpt,Heading(2,['Z2AHU1(Zn4) zone temperature control: ' sys_performance.T_z2_ahu1.flag])); 
add(rpt,...
    {['Zone temperature is ' num2str(Tz_e) ' °C higher than the setpoint for ' num2str(sys_performance.T_z2_ahu1.time_high) ' timesteps'],... 
    ['Zone temperature is ' num2str(Tz_e) ' °C lower than the setpoint for ' num2str(sys_performance.T_z2_ahu1.time_low) ' timesteps']}); 
add(rpt,Heading(2,['Z1AHU2(Zn1) zone temperature control: ' sys_performance.T_z1_ahu2.flag])); 
add(rpt,...
    {['Zone temperature is ' num2str(Tz_e) ' °C higher than the setpoint for ' num2str(sys_performance.T_z1_ahu2.time_high) ' timesteps'],... 
    ['Zone temperature is ' num2str(Tz_e) ' °C lower than the setpoint for ' num2str(sys_performance.T_z1_ahu2.time_low) ' timesteps']}); 
add(rpt,Heading(2,['Z2AHU2(Zn2) zone temperature control: ' sys_performance.T_z2_ahu2.flag])); 
add(rpt,...
    {['Zone temperature is ' num2str(Tz_e) ' °C higher than the setpoint for ' num2str(sys_performance.T_z2_ahu2.time_high) ' timesteps'],... 
    ['Zone temperature is ' num2str(Tz_e) ' °C lower than the setpoint for ' num2str(sys_performance.T_z2_ahu2.time_low) ' timesteps']});
% AHU1 supply air temperature control
add(rpt,Heading(2,['AHU1 supply air temperature control: ' sys_performance.T_SA_ahu1.flag])); 
add(rpt,...
    {['AHU supply air temperature is ' num2str(T_SA_e) ' °C higher than the setpoint for ' num2str(sys_performance.T_SA_ahu1.time_notmet) ' timesteps']});
add(rpt,Heading(2,['AHU2 supply air temperature control: ' sys_performance.T_SA_ahu2.flag])); 
add(rpt,...
    {['AHU supply air temperature is ' num2str(T_SA_e) ' °C higher than the setpoint for ' num2str(sys_performance.T_SA_ahu2.time_notmet) ' timesteps']});
% AHU1 static pressure control
add(rpt,Heading(2,['AHU1 static pressure control: ' sys_performance.P_sp_ahu1.flag])); 
add(rpt,...
    {['AHU static pressure is ' num2str(P_sp_e) ' Pa lower than the setpoint for ' num2str(sys_performance.P_sp_ahu1.time_notmet) ' timesteps']});
add(rpt,Heading(2,['AHU2 static pressure control: ' sys_performance.P_sp_ahu2.flag])); 
add(rpt,...
    {['AHU static pressure is ' num2str(P_sp_e) ' Pa lower than the setpoint for ' num2str(sys_performance.P_sp_ahu2.time_notmet) ' timesteps']});
% chilled 1 water temperature control
add(rpt,Heading(2,['Chiller 1 supply temperature control: ' sys_performance.T_ch1.flag])); 
add(rpt,{});
add(rpt,...
    {['Chiller 1 is on for ' num2str(sum((ch1_on.*ch1_power)>900)) ' timesteps'],...
    ['Chilled water supply temperature is ' num2str(T_chwst_e) ...
    ' °C higher than the setpoint for ' num2str(sys_performance.T_ch1.time_notmet) ' timesteps']});
% chilled 2 water temperature control
add(rpt,Heading(2,['Chiller 2 supply temperature control: ' sys_performance.T_ch2.flag])); 
add(rpt,...
    {['Chiller 2 is on for ' num2str(sum((ch2_on.*ch2_power)>900)) ' timesteps'],...
    ['Chilled water supply temperature is ' num2str(T_chwst_e) ...
    ' °C higher than the setpoint for ' num2str(sys_performance.T_ch2.time_notmet) ' timesteps']});
% chilled water seoncdary-loop differential pressure
add(rpt,Heading(2,['Chilled water seoncdary-loop differential pressure control: ' sys_performance.DP_slSP.flag])); 
add(rpt,...
    {['Chilled water seoncdary-loop differential pressure is ' num2str(DP_slSP_e) ' kPa lower than the setpoint for ' num2str(sys_performance.DP_slSP.time_notmet) ' timesteps']});
% ------------plot-------------------
add(rpt,Heading(1,'Plots'));
% Communication delay
add(rpt,Heading(2,'Communication delay'));
f = figure('visible','on');
f.Position = [600 400 400 220];
scatter([rt_start:rt_end],delay,'.');
xlabel ('Timestep');
xlim([0 24*60]);
xticks([0:180:24*60]);
yticks([0:1:20]);
ylabel('Communication delay')
grid on
saveas(f,[pwd '/' report_path '/ComDelay.png']);
saveas(f,[pwd '/' report_path '/ComDelay.fig']);
img1 = Image([pwd '/' report_path '/ComDelay.png']);
add(rpt,img1);
set(f, 'Visible', 'off')
% frequency regulation
if (GEB_case == 4)
label = {'ahu1','ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' frequency regulation']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp_sp = ' label{i} '_fr_Powerset;']);
    eval(['temp_pv = ' label{i} '_power_ext;']);
    scatter([10:10:length(temp_sp)*10],temp_sp,'.');hold on
    scatter([10-5*60:10:length(temp_sp)*10+5*60],temp_pv,'.');
    xlabel ('Time [second]');
    ylabel('Power [W]');
    legend('FR signal','Actual fan power',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' label{i} '_fr.png']);
    saveas(f,[pwd '/' report_path '/' label{i} '_fr.fig']);
    img1 = Image([pwd '/' report_path '/' label{i} '_fr.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
end
% temperature emulation
label = {'T_z1_ahu1','T_z2_ahu1','T_z1_ahu2','T_z2_ahu2','T_out'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' emulation accuracy']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp_sim = ' label{i} '_sim;']);
    eval(['temp_mea = ' label{i} '_mea;']);
    scatter(Timestep_sim(occ_start:peval_end),temp_sim(occ_start:peval_end),'.');hold on
    scatter(Timestep_mea(occ_start:peval_end),temp_mea(occ_start:peval_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Temperature [°C]');
    legend('Simulated temperature','Emulated temperature',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% humidity emulation
label = {'w_z1_ahu1','w_z2_ahu1','w_z1_ahu2','w_z2_ahu2','RH_out'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' emulation accuracy']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp_sim = ' label{i} '_sim;']);
    eval(['temp_mea = ' label{i} '_mea;']);
    scatter(Timestep_sim(occ_start:occ_end),temp_sim(occ_start:occ_end),'.');hold on
    scatter(Timestep_mea(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Humidity ratio [kg/kg]');
	ylim([0 0.02]);
    if i>4
        ylabel('Relative humidity [%]');
        ylim([0 100]);
    end
    legend('Simulated','Emulated',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% sensible load emulation
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' sensible load emulation accuracy']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp_sim = -Qsen_' label{i} '_sim;']);
    eval(['temp_mea = -Qsen_' label{i} '_mea;']);
    scatter(Timestep_sim(occ_start:occ_end),temp_sim(occ_start:occ_end),'.');hold on
    scatter(Timestep_mea(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Power [W]');
    legend('Simulated sensible load','Emulated sensible load',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' 'Qsen_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' 'Qsen_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' 'Qsen_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% latent load emulation
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' latent load emulation accuracy']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp_sim = -Qlat_' label{i} '_sim;']);
    eval(['temp_mea = -Qlat_' label{i} '_mea;']);
%     eval(['temp_uncertainty = uQlat_' label{i} ';']);
    scatter(Timestep_sim(occ_start:occ_end),temp_sim(occ_start:occ_end),'.');hold on
    scatter(Timestep_mea(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');%hold on
%     scatter(Timestep_mea(occ_start:occ_end),temp_mea(occ_start:occ_end)+temp_uncertainty(occ_start:occ_end),'.','k');hold on
%     scatter(Timestep_mea(occ_start:occ_end),temp_mea(occ_start:occ_end)-temp_uncertainty(occ_start:occ_end),'.','k');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Power [W]');
%     legend('Simulated latent load','Emulated latent load','Emulated latent load uncertainty',...
%         'Location','northoutside');
    legend('Simulated latent load','Emulated latent load',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' 'Qlat_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' 'Qlat_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' 'Qlat_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% vav discharge air humidity ratio
label = {'w_sup_vav1_ahu1','w_sup_vav2_ahu1','w_sup_vav1_ahu2','w_sup_vav2_ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' emulation accuracy']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp_sim = ' label{i} '_eplus;']);
    eval(['temp_mea = ' label{i} '_mea;']);
    scatter(Timestep_sim(occ_start:occ_end),temp_sim(occ_start:occ_end),'.');hold on
    scatter(Timestep_mea(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Humidity ratio [kg/kg]');
    ylim([0 0.02]);
    legend('Humidity ratio used in simulation','Measured humidity ratio',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% zone temperature control
label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' zone air temperature control']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
	eval(['temp_cspt = Tz_cspt_' label{i} ';']);
	eval(['temp_hspt = Tz_hspt_' label{i} ';']);
    eval(['temp_sim = T_' label{i} '_sim;']);
    scatter(Timestep_sim,temp_cspt,'.');hold on
    scatter(Timestep_sim,temp_sim,'.');hold on
    scatter(Timestep_sim,temp_hspt,'.');
    ylabel('Temperature [°C]');
    yticks([10:2:40]);
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    legend('Zone air temperature cooling setpoint','Zone air temperature',...
        'Zone air temperature heating setpoint','Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' 'T_' label{i} '_spt.png']);
    saveas(f,[pwd '/' report_path '/' 'T_' label{i} '_spt.fig']);
    img1 = Image([pwd '/' report_path '/' 'T_' label{i} '_spt.png']);
    add(rpt,img1);
	set(f, 'Visible', 'off')
end
% AHU supply air temperature control
label = {'ahu1','ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' supply air temperature control']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
	eval(['temp_spt = T_SA_' label{i} ';']);
    eval(['temp_mea = T_SA_' label{i} '_mea;']);
    scatter(Timestep_sim(occ_start:occ_end),temp_spt(occ_start:occ_end,2),'.');hold on
    scatter(Timestep_sim(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    yticks([0:2:24]);
    ylabel('Temperature [°C]');
    ylim([0, max(ylim)]);
    legend('AHU supply air temperature setpoint','AHU supply air temperature',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' 'T_SA_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' 'T_SA_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' 'T_SA_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% AHU supply air static pressure control
label = {'ahu1','ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' supply air static pressure control']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
	eval(['temp_spt = P_sp_' label{i} ';']);
    eval(['temp_mea = P_sp_' label{i} '_mea;']);
    scatter(Timestep_sim(occ_start:occ_end),temp_spt(occ_start:occ_end,2),'.');hold on
    scatter(Timestep_sim(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Pressure [Pa]');
    legend('AHU supply air static pressure setpoint','AHU supply air static pressure',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' 'P_sp_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' 'P_sp_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' 'P_sp_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% Chilled water temperature control
label = {'ch1','ch2'};
labelname = {'Chiller 1','Chiller 2'};
for i=1:length(label)
    add(rpt,Heading(2,[labelname{i} ' water supply temperature control']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
	eval(['temp_mea = T_' label{i} ';']);
    scatter(Timestep_sim(occ_start:occ_end),T_chwst(occ_start:occ_end,2),'.');hold on
    scatter(Timestep_sim(occ_start:occ_end),temp_mea(occ_start:occ_end),'.');
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Temperature [°C]');
    ylim([0, max(ylim)]);
    legend('Chilled water supply temperature setpoint','Chilled water supply temperature',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' 'T_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' 'T_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' 'T_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% Chilled water secondary-loop differential pressure control
add(rpt,Heading(2,'Chilled water secondary-loop differential pressure control'));
f = figure('visible','on');
f.Position = [600 400 400 220];
scatter(Timestep_sim(occ_start:occ_end),DP_slSP(occ_start:occ_end,2),'.');hold on
scatter(Timestep_sim(occ_start:occ_end),DP_slSP_mea(occ_start:occ_end),'.');
xlabel ('Timestep');
xlim([0 24*60]);
xticks([0:180:24*60]);
ylabel('Pressure [kPa]');
legend('Chilled water secondary-loop differential pressure setpoint','Chilled water secondary-loop differential pressure',...
    'Location','northoutside');
grid on
saveas(f,[pwd '/' report_path '/' 'DP_slSP.png']);
saveas(f,[pwd '/' report_path '/' 'DP_slSP.fig']);
img1 = Image([pwd '/' report_path '/' 'DP_slSP.png']);
add(rpt,img1);
set(f, 'Visible', 'off')
% vav damper position
label = {'d1_ahu1_mea','d2_ahu1_mea','d1_ahu2_mea','d2_ahu2_mea'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' zone vav damper control']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp = ' label{i} ';']);
    d_low = 5 + zeros(1,1441);
    d_high = 7 + zeros(1,1441);
    scatter(Timestep_sim(occ_start:occ_end),temp(occ_start:occ_end),'.');hold on
    scatter([1:1441],d_low,'.');hold on
    scatter([1:1441],d_high,'.');
    ylabel('Damper position [V]');
    ylim([0, max(ylim)]);
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    title(['Damper position: ' label{i}],'Interpreter', 'none');
%     yticks([0:1:10]);
    legend('Damper position','High threshold for reset','Low threshold for reset',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% vav reheat valve position
label = {'rh1_ahu1_mea','rh2_ahu1_mea','rh1_ahu2_mea','rh2_ahu2_mea'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' zone vav reheat valve control']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp = ' label{i} ';']);
    scatter(Timestep_sim(occ_start:occ_end),temp(occ_start:occ_end),'.');
    ylabel('Valve position [V]');
    ylim([0, max(ylim)]);
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
%     yticks([0:1:10]);
    legend('Valve position',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% vav flow rate setpoint
label = {'vav1_ahu1','vav2_ahu1','vav1_ahu2','vav2_ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' zone vav airflow setpoint']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp = CFMspt_' label{i} ';']);
    scatter(Timestep_sim(occ_start:occ_end),temp(occ_start:occ_end),'.');
    ylabel('Flow rate [CFM]');
    ylim([0, max(ylim)]);
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    legend('Airflow setpoint',...
        'Location','northoutside');
    grid on
    saveas(f,[pwd '/' report_path '/CFMspt_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/CFMspt_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/CFMspt_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% vav mass flow rate
label = {'vav1_ahu1','vav2_ahu1','vav1_ahu2','vav2_ahu2'};
for i=1:length(label)
    add(rpt,Heading(2,[label{i} ' zone vav discharge air mass flow rate']));
    f = figure('visible','on');
    f.Position = [600 400 400 220];
    eval(['temp = m_sup_' label{i} '_eplus;']);
    scatter(Timestep_sim,temp,'.');
    ylabel('Mass flor rate [kg/s]');
    ylim([0, max(ylim)]);
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    legend([label{i} ' mass flow rate'],...
        'Location','northoutside', 'Interpreter', 'none');
    grid on
    saveas(f,[pwd '/' report_path '/m_sup_' label{i} '.png']);
    saveas(f,[pwd '/' report_path '/m_sup_' label{i} '.fig']);
    img1 = Image([pwd '/' report_path '/m_sup_' label{i} '.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% personal fan power
for i=1
    add(rpt,Heading(2,'personal fan power'));
    f = figure('visible','on');
    f.Position = [600 400 400 400];
    area(Timestep_sim(occ_start:occ_end),...
        [power_pf_z1_ahu1_eplus(occ_start:occ_end)';...
        power_pf_z2_ahu1_eplus(occ_start:occ_end)';...
        power_pf_z1_ahu2_eplus(occ_start:occ_end)';...
        power_pf_z2_ahu2_eplus(occ_start:occ_end)']')
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Power [W]');
    ylim([0, max(ylim)]);
    legend({'pf_power_z1_ahu1', 'pf_power_z2_ahu1', 'pf_power_z1_ahu2', 'pf_power_z2_ahu2'},...
        'Location','northoutside', 'Interpreter', 'none');
    grid on
    saveas(f,[pwd '/' report_path '/' 'Power_pfan.png']);
    saveas(f,[pwd '/' report_path '/' 'Power_pfan.fig']);
    img1 = Image([pwd '/' report_path '/' 'Power_pfan.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% personal heater power
for i=1
    add(rpt,Heading(2,'personal heater power'));
    f = figure('visible','on');
    f.Position = [600 400 400 400];
    area(Timestep_sim(occ_start:occ_end),...
        [power_ph_z1_ahu1_eplus(occ_start:occ_end)';...
        power_ph_z2_ahu1_eplus(occ_start:occ_end)';...
        power_ph_z1_ahu2_eplus(occ_start:occ_end)';...
        power_ph_z2_ahu2_eplus(occ_start:occ_end)']')
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Power [W]');
    ylim([0, max(ylim)]);
    legend({'ph_power_z1_ahu1', 'ph_power_z2_ahu1', 'ph_power_z1_ahu2', 'ph_power_z2_ahu2'},...
        'Location','northoutside', 'Interpreter', 'none');
    grid on
    saveas(f,[pwd '/' report_path '/' 'Power_pheat.png']);
    saveas(f,[pwd '/' report_path '/' 'Power_pheat.fig']);
    img1 = Image([pwd '/' report_path '/' 'Power_pheat.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% AHU1 power
for i=1
    add(rpt,Heading(2,'AHU1 airside power'));
    f = figure('visible','on');
    f.Position = [600 400 400 400];
    area(Timestep_sim(occ_start:occ_end),...
        [vav3_heat_power(occ_start:occ_end);...
        vav4_heat_power(occ_start:occ_end);...
        ahu1_fan_power(occ_start:occ_end)]')
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Power [W]');
    ylim([0, max(ylim)]);
    legend({'VAV1_AHU1 reheat power','VAV2_AHU1 reheat power','AHU1 fan power'},...
        'Location','northoutside', 'Interpreter', 'none');
    grid on
    saveas(f,[pwd '/' report_path '/' 'Power_AHU1.png']);
    saveas(f,[pwd '/' report_path '/' 'Power_AHU1.fig']);
    img1 = Image([pwd '/' report_path '/' 'Power_AHU1.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% AHU2 power
for i=1
    add(rpt,Heading(2,'AHU2 airside power'));
    f = figure('visible','on');
    f.Position = [600 400 400 400];
    area(Timestep_sim(occ_start:occ_end),...
        [vav1_heat_power(occ_start:occ_end);...
        vav2_heat_power(occ_start:occ_end);...
        ahu1_fan_power(occ_start:occ_end)]')
    xlabel ('Timestep');
    xlim([0 24*60]);
    xticks([0:180:24*60]);
    ylabel('Power [W]');
    ylim([0, max(ylim)]);
    legend({'VAV1_AHU2 reheat power','VAV2_AHU2 reheat power','AHU2 fan power'},...
        'Location','northoutside', 'Interpreter', 'none');
    grid on
    saveas(f,[pwd '/' report_path '/' 'Power_AHU2.png']);
    saveas(f,[pwd '/' report_path '/' 'Power_AHU2.fig']);
    img1 = Image([pwd '/' report_path '/' 'Power_AHU2.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')
end
% waterside power
if ~TES
    for i=1
        add(rpt,Heading(2,'HVAC waterside power'));
        f = figure('visible','on');
        f.Position = [600 400 400 400];
        area(Timestep_sim(occ_start:occ_end),...
            [pump1_power(occ_start:occ_end);...
            pump2_power(occ_start:occ_end);...
            pump3_power(occ_start:occ_end);...
            pump4_power(occ_start:occ_end);...
            ch1_power(occ_start:occ_end);...
            ch2_power(occ_start:occ_end)]')
        xlabel ('Timestep');
        xlim([0 24*60]);
        xticks([0:180:24*60]);
        ylabel('Power [W]');
        ylim([0, max(ylim)]);
        legend({'pump1 power', 'pump2 power','pump3 power','pump4 power','chiller1 power', 'chiller2 power'},...
            'Location','northoutside', 'Interpreter', 'none');
        grid on
        saveas(f,[pwd '/' report_path '/' 'Power_waterside.png']);
        saveas(f,[pwd '/' report_path '/' 'Power_waterside.fig']);
        img1 = Image([pwd '/' report_path '/' 'Power_waterside.png']);
        add(rpt,img1);
        set(f, 'Visible', 'off')
    end
else
    for i=1
        add(rpt,Heading(2,'HVAC waterside power'));
        f = figure('visible','on');
        f.Position = [600 400 400 400];
        area([-239:1440],...
            [pump1_power_all;...
            pump2_power_all;...
            pump3_power_all;...
            pump4_power_all;...
            ch1_power_all;...
            ch2_power_all]')
        xlabel ('Timestep');
        xlim([-4*60 24*60]);
        xticks([-4*60:180:24*60]);
        ylabel('Power [W]');
        ylim([0, max(ylim)]);
        legend({'pump1 power', 'pump2 power','pump3 power','pump4 power','chiller1 power', 'chiller2 power'},...
            'Location','northoutside', 'Interpreter', 'none');
        grid on
        saveas(f,[pwd '/' report_path '/' 'Power_waterside.png']);
        saveas(f,[pwd '/' report_path '/' 'Power_waterside.fig']);
        img1 = Image([pwd '/' report_path '/' 'Power_waterside.png']);
        add(rpt,img1);
        set(f, 'Visible', 'off')
    end    
end
% total HVAC power
if ~TES
    for i=1
        add(rpt,Heading(2,'Total HVAC power'));
        f = figure('visible','on');
        f.Position = [600 400 400 400];
        area(Timestep_sim(occ_start:occ_end),...
            [airside_ahu1_power(occ_start:occ_end);...
            airside_ahu2_power(occ_start:occ_end);...
            waterside_power(occ_start:occ_end)]')
        xlabel ('Timestep');
        xlim([0 24*60]);
        xticks([0:180:24*60]);
        ylabel('Power [W]');
        ylim([0, max(ylim)]);
        legend({'AHU1 power', 'AHU2 power','waterside power', 'personal fan power', 'personal heater power'},...
            'Location','northoutside', 'Interpreter', 'none');
        grid on
        saveas(f,[pwd '/' report_path '/' 'Power_HVAC.png']);
        saveas(f,[pwd '/' report_path '/' 'Power_HVAC.fig']);
        img1 = Image([pwd '/' report_path '/' 'Power_HVAC.png']);
        add(rpt,img1);
        set(f, 'Visible', 'off')
    end
else
    for i=1
        add(rpt,Heading(2,'Total HVAC power'));
        f = figure('visible','on');
        f.Position = [600 400 400 400];
        area([-239:1440],...
            [airside_ahu1_power_all;...
            airside_ahu2_power_all;...
            waterside_power_all]')
        xlabel ('Timestep');
        xlim([-4*60 24*60]);
        xticks([-4*60:180:24*60]);
        ylabel('Power [W]');
        ylim([0, max(ylim)]);
        legend({'AHU1 power', 'AHU2 power','waterside power'},...
            'Location','northoutside', 'Interpreter', 'none');
        grid on
        saveas(f,[pwd '/' report_path '/' 'Power_HVAC.png']);
        saveas(f,[pwd '/' report_path '/' 'Power_HVAC.fig']);
        img1 = Image([pwd '/' report_path '/' 'Power_HVAC.png']);
        add(rpt,img1);
        set(f, 'Visible', 'off')
    end    
end
% total power
if ~TES
    for i=1
        add(rpt,Heading(2,'Total power'));
        f = figure('visible','on');
        f.Position = [600 400 400 400];
        area(Timestep_sim(occ_start:occ_end),...
            [airside_ahu1_power(occ_start:occ_end);...
            airside_ahu2_power(occ_start:occ_end);...
            waterside_power(occ_start:occ_end);...
            power_pf(occ_start:occ_end)';...
            power_ph(occ_start:occ_end)']')
        xlabel ('Timestep');
        xlim([0 24*60]);
        xticks([0:180:24*60]);
        ylabel('Power [W]');
        ylim([0, max(ylim)]);
        legend({'AHU1 power', 'AHU2 power','waterside power', 'personal fan power', 'personal heater power'},...
            'Location','northoutside', 'Interpreter', 'none');
        grid on
        saveas(f,[pwd '/' report_path '/' 'Power_total.png']);
        saveas(f,[pwd '/' report_path '/' 'Power_total.fig']);
        img1 = Image([pwd '/' report_path '/' 'Power_total.png']);
        add(rpt,img1);
        set(f, 'Visible', 'off')
    end
else
    for i=1
        add(rpt,Heading(2,'Total power'));
        f = figure('visible','on');
        f.Position = [600 400 400 400];
        area([-239:1440],...
            [airside_ahu1_power_all;...
            airside_ahu2_power_all;...
            waterside_power_all;...
            [repmat([0],1,239),power_pf'];...
            [repmat([0],1,239),power_ph']]')
        xlabel ('Timestep');
        xlim([-4*60 24*60]);
        xticks([-4*60:180:24*60]);
        ylabel('Power [W]');
        ylim([0, max(ylim)]);
        legend({'AHU1 power', 'AHU2 power','waterside power', 'personal fan power', 'personal heater power'},...
            'Location','northoutside', 'Interpreter', 'none');
        grid on
        saveas(f,[pwd '/' report_path '/' 'Power_total.png']);
        saveas(f,[pwd '/' report_path '/' 'Power_total.fig']);
        img1 = Image([pwd '/' report_path '/' 'Power_total.png']);
        add(rpt,img1);
        set(f, 'Visible', 'off')
    end    
end
% ice tank inventory
if TES
for i=1
    add(rpt,Heading(2,'Ice tank inventory'));
    f = figure('visible','on');
    f.Position = [600 400 400 400];
    area([-239:1440],...
        [ts_meter_pday;ts_meter])
    xlabel ('Timestep');
    xlim([-4*60 24*60]);
    xticks([-4*60:180:24*60]);
    ylabel('Inventory [%]');
    ylim([0, max(ylim)]);
    legend({'TES_inventory'},...
        'Location','northoutside', 'Interpreter', 'none');
    grid on
    saveas(f,[pwd '/' report_path '/' 'TES_inventory.png']);
    saveas(f,[pwd '/' report_path '/' 'TES_inventory.fig']);
    img1 = Image([pwd '/' report_path '/' 'TES_inventory.png']);
    add(rpt,img1);
    set(f, 'Visible', 'off')    
end
end
% finalize report
close(rpt);
rptview(rpt);
%% Code for reuse
% AHU supply air static pressure setpoint supervisory control
% label = {'d1_ahu1','d2_ahu2'};
for i=1:length(label)
%     add(rpt,Heading(2,[upper(label{i}) ' supply air static pressure setpoint supervisory control']));
%     f = figure('visible','on');
%     f.Position = [600 400 400 220];
% 	eval(['temp_spt = P_sp_' label{i} ';']);
% %     eval(['temp_d1 = d1_' label{i} ';']);
% %     eval(['temp_d2 = d2_' label{i} ';']);
% %     yyaxis left
%     plot(Timestep_sim(occ_start:occ_end),temp_spt(occ_start:occ_end,2));
% 	ylabel('Pressure [Pa]');
% %     yyaxis right
% %     plot(Timestep_sim(occ_start:occ_end),temp_d1(occ_start:occ_end));hold on 
% %     plot(Timestep_sim(occ_start:occ_end),temp_d2(occ_start:occ_end));
% %     ylabel('Damper position [V]');
%     xlabel ('Timestep');
%     xlim([0 24*60]);
%     xticks([0:180:24*60]);
%     yticks([0:1:10]);
% %     legend('AHU supply air static pressure setpoint','Damper 1 position','Damper 2 position',...
% %         'Location','northoutside');
%     legend('AHU supply air static pressure setpoint',...
%         'Location','northoutside');
%     grid on
%     saveas(f,[pwd '/' filename '/' 'P_sp_' label{i} '_spt.png']);
%     saveas(f,[pwd '/' filename '/' 'P_sp_' label{i} '_spt.fig']);
%     img1 = Image([pwd '/' filename '/' 'P_sp_' label{i} '_spt.png']);
%     add(rpt,img1);
%     set(f, 'Visible', 'off')
end
% Zone Relative Humidity
% label = {'z1_ahu1','z2_ahu1','z1_ahu2','z2_ahu2'};
for i=1:length(label)
% 	add(rpt,Heading(2,[label{i} ' relative humidity emulation accuracy: ' eval(['emu_accuracy.RH_' label{i} '.flag'])]));
%     add(rpt,...
%         {['Criteria: RMSE <= ' num2str(RH_emu_etol) ' %RH'],...
%         ['RMSE: ' num2str(eval(['emu_accuracy.RH_' label{i} '.rmse'])) ' %RH'],... 
%         ['NRMSE: ' num2str(eval(['emu_accuracy.RH_' label{i} '.nrmse']))],...
%         ['Simulated Mean: ' num2str(eval(['emu_accuracy.RH_' label{i} '.sim_mean'])) ' %RH'],...
%         ['Emulated Mean: ' num2str(eval(['emu_accuracy.RH_' label{i} '.emu_mean'])) ' %RH']});     
end