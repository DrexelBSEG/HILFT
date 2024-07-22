function [ZoneInfo,CtrlSig]=callSim(HardwareTime,timestep,Meas,Meas_MPC)
%% Notes
%% Inputs
% timestep
%   User should put callSim function in a loop, where timestep=0:1:end
% Meas:
%     m_sup_vav1_ahu1 = Meas(1) :       vav discharge air mass flow rate of zone 1 served by AHU1 [kg/s]
%     T_sup_vav1_ahu1 = Meas(2) :       vav discharge air temperature of zone 1 served by AHU1 [°C]
%     w_sup_vav1_ahu1 = Meas(3) :       vav discharge air humidity ratio of zone 1 served by AHU1 [kg/kg]
%     T_z1_ahu1 = Meas(4) :             zone air temperature of zone 1 served by AHU1 [°C]
%     w_z1_ahu1 = Meas(5) :             humidity ratio of zone 1 served by AHU1 [kg/kg]
%     m_sup_vav2_ahu1 = Meas(6) :       vav discharge air mass flow rate of zone 2 served by AHU1 [kg/s]
%     T_sup_vav2_ahu1 = Meas(7) :       vav discharge air temperature of zone 2 served by AHU1 [°C]
%     w_sup_vav2_ahu1 = Meas(8) :       vav humidity ratio of zone 2 served by AHU1 [kg/kg]
%     T_z2_ahu1 = Meas(9) :             zone air temperature of zone 2 served by AHU1 [°C]
%     w_z2_ahu1 = Meas(10) :            humidity ratio of zone 2 served by AHU1 [kg/kg]
%     m_sup_vav1_ahu2 = Meas(11) :      vav discharge air mass flow rate of zone 1 served by AHU2 [kg/s]
%     T_sup_vav1_ahu2 = Meas(12) :      vav discharge air temperature of zone 1 served by AHU2 [°C]
%     w_sup_vav1_ahu2 = Meas(13) :      vav humidity ratio of zone 1 served by AHU2 [kg/kg]
%     T_z1_ahu2 = Meas(14) :            zone air temperature of zone 1 served by AHU2 [°C]
%     w_z1_ahu2 = Meas(15) :            humidity ratio of zone 1 served by AHU2 [kg/kg]
%     m_sup_vav2_ahu2 = Meas(16) :      vav discharge air mass flow rate of zone 2 served by AHU2 [kg/s]
%     T_sup_vav2_ahu2 = Meas(17) :      vav discharge air temperature of zone 2 served by AHU2 [°C]
%     w_sup_vav2_ahu2 = Meas(18) :      vav humidity ratio of zone 2 served by AHU2 [kg/kg]
%     T_z2_ahu2 = Meas(19) :            zone air temperature of zone 2 served by AHU2 [°C]
%     w_z2_ahu2 = Meas(20) :            humidity ratio of zone 2 served by AHU2 [kg/kg]
%     W_ahu1 = Meas(21) :               AHU1 power [W]
%     vfd_ahu1 = Meas(22) :             AHU1 fan speed [Hz]
%     d1_ahu1 = Meas(23) :              vav damper position of zone 1 served by AHU1 [V]
%     d2_ahu1 = Meas(24) :              vav damper position of zone 2 served by AHU1 [V]
%     rh1_ahu1 = Meas(25) :             reheat coil status (0 or 1) of zone 1 served by AHU1
%     rh2_ahu1 = Meas(26) :             reheat coil status (0 or 1) of zone 2 served by AHU1
%     P_sp_ahu1_cur = Meas(27) :        AHU1 current static pressure measurement [Pa]
%     T_SA_ahu1_cur = Meas(28) :        AHU1 current supply air temperature measurement [°C]
%     V_cc_ahu1 = Meas(29) :            AHU1 Cooling coil valve position [V]
%     Tin_cc_ahu1 = Meas(30) :          AHU1 Cooling coil inlet temperature [°C]
%     Tout_cc_ahu1 = Meas(31) :         AHU1 Cooling coil outlet temperature [°C]
%     W_ahu2 = Meas(32) :               AHU2 power [W]
%     vfd_ahu2 = Meas(33) :             AHU2 fan speed [Hz]
%     d1_ahu2 = Meas(34) :              vav damper position of zone 1 served by AHU2 [V]
%     d2_ahu2 = Meas(35) :              vav damper position of zone 2 served by AHU2 [V]
%     rh1_ahu2 = Meas(36) :             reheat coil status (0 or 1) of zone 1 served by AHU2
%     rh2_ahu2 = Meas(37) :             reheat coil status (0 or 1) of zone 2 served by AHU2
%     P_sp_ahu2_cur = Meas(38) :        AHU2 current static pressure measurement [Pa]
%     T_SA_ahu2_cur = Meas(39) :        AHU2 current supply air temperature measurement [°C]
%     V_cc_ahu2 = Meas(40) :            AHU2 Cooling coil valve position [V]
%     Tin_cc_ahu2 = Meas(41) :          AHU2 Cooling coil inlet temperature [°C]
%     Tout_cc_ahu2 = Meas(42) :         AHU2 Cooling coil outlet temperature [°C]
%     W_CHW = Meas(43) :                chiller power [W]
%     m_CHW_pm = Meas(44) :             primary chilled water pump flow rate [kg/s]
%     m_CHW_sl = Meas(45) :             secondary chilled water pump flow rate [kg/s]
%     T_CHW1 = Meas(46) :               chiller1 chilled water supply temperature [°C]
%     T_CHW2 = Meas(47) :               chiller2 chilled water supply temperature [°C]
%     T_CHW_TS = Meas(48) :             ice tank chilled water supply temperature [°C]
%     T_chwst_cur = Meas(49) :          current chilled water temperature measurement[°C]
%     DP_slSP_cur = Meas(50):           current chilled water secondary loop pressure measurement[kPa]
%     TES_inventory = Meas(51):         current ice tank inventory level (0 to 100%)
%     TES_status = Meas(52):            current ice tank status (0-charing/discharging,1-fully discharged,2-fully charged)
%     T_out_emulated = Meas(53):        emulated outdoor air temperature [°C]
%     T_return_ahu1 = Meas(54):         return air temperature of AHU1 [°C]
%     T_return_ahu2 = Meas(55):         return air temperature of AHU2 [°C]
%     Power_HVAC_electric = Meas(56):   total electric power of HVAC system including primary/secondary system [kW]
%
% Meas_MPC:
%     pump4_out_rtd = Meas_MPC(1):       Temperature of the water entering the condenser in Chiller1(Temperature downstream of Pump4) [F]
%     ch1_c_out_rtd = Meas_MPC(2):       Temperature of the water leaving the condenser in Chiller1 [F]
%     ch1_f_c = Meas_MPC(3):             Flow rate of the water through the condenser in Chiller1 [gpm]
%     ch1_e_in_rtd = Meas_MPC(4):        Temperature of the PG returning to Chiller1 [F]
%     ch1_e_out_rtd = Meas_MPC(5):       Temperature of the PG leaving the evaporator in Chiller1 [f]
%     ch1_f_e = Meas_MPC(6):             Flow rate of the PG through the evaporator in Chiller1 [gpm]
%     ch1_power = Meas_MPC(7):           Power consumption of Chiller1 [W]
%     pump4_out_rtd = Meas_MPC(8):       Temperature of the water entering the condenser in Chiller2(Temperature downstream of Pump4) [F]
%     ch2_c_out_rtd = Meas_MPC(9):       Temperature of the water leaving the condenser in Chiller2 [F]
%     ch2_f_c = Meas_MPC(10):            Flow rate of the water through the condenser in Chiller2 [gpm]
%     ch2_e_in_rtd = Meas_MPC(11):       Temperature of the PG returning to Chiller2 [F]
%     ch2_e_out_rtd = Meas_MPC(12):      Temperature of the PG leaving the evaporator in Chiller2 [F]
%     ch2_f_e = Meas_MPC(13):            Flow rate of the PG through the evaporator in Chiller2 [gpm]
%     ch2_power = Meas_MPC(14):          Power consumption of Chiller1 [W]
%     ts_in_rtd = Meas_MPC(15):          Temperature of the PG entering the thermal storage tank [F]
%     ts_out_rtd = Meas_MPC(16):         Temperature of the PG leaving the thermal storage tank [F]
%     ts_f = Meas_MPC(17):               Flow rate through the thermal storage tank [gpm]
%     ts_meter = Meas_MPC(18):           Ice meter reading of the inventory in the thermal storage tank [%]
%     pl_f = Meas_MPC(19):               Flow rate in the primary loop [gpm]
%     sl_f = Meas_MPC(20):               Flow rate in the secondary loop [gpm]
%     pump1_power = Meas_MPC(21):        Power consumption of Pump1 (chiller 1 primary) [W]
%     pump2_power = Meas_MPC(22):        Power consumption of Pump2 (chiller 2 primary) [W]
%     pump3_power = Meas_MPC(23):        Power consumption of Pump3 (secondary) [W]
%     ahu1_cc_in_rtd = Meas_MPC(24):     Temperature of the propylene glycol entering the cooling coil in AHU1 [F]
%     ahu1_cc_out_rtd = Meas_MPC(25):    Temperature of the propylene glycol leaving the cooling coil in AHU1 [F]
%     ahu1_f_cc = Meas_MPC(26):          Flow rate of PG through the cooling coil in AHU1 [gpm]
%     ahu1_in_rtd = Meas_MPC(27):        Temperature at the inlet of AHU1, after the return and supply air are mixed [F]
%     ahu1_out_rtd = Meas_MPC(28):       Temperature downstream of AHU1 [F]
%     ahu1_f_ra = Meas_MPC(29):          Return airflow rate in AHU1 [cfm]
%     ahu1_f_sa = Meas_MPC(30):          Supply airflow rate in AHU1 [cfm]
%     ahu1_fan_power = Meas_MPC(31):     Power consumption of the AHU1 supply fan [W]
%     ahu2_cc_in_rtd = Meas_MPC(32):     Temperature of the propylene glycol entering the cooling coil in AHU2 [F]
%     ahu2_cc_out_rtd = Meas_MPC(33):    Temperature of the propylene glycol leaving the cooling coil in AHU2 [F]
%     ahu2_f_cc = Meas_MPC(34):          Flow rate of PG through the cooling coil in AHU2 [gpm]
%     ahu2_in_rtd = Meas_MPC(35):        Temperature at the inlet of AHU2, after the return and supply air are mixed [F]
%     ahu2_out_rtd = Meas_MPC(36):       Temperature downstream of AHU2 [F]
%     ahu2_f_ra = Meas_MPC(37):          Return airflow rate in AHU2 [cfm]
%     ahu2_f_sa = Meas_MPC(38):          Supply airflow rate in AHU2 [cfm]
%     ahu2_fan_power = Meas_MPC(39):     Power consumption of the AHU2 supply fan [W]
%     
%     vav3_d_sp = Meas_MPC(40):          Flow setpont for VAV3 [CFM]
%     vav4_d_sp = Meas_MPC(41):          Flow setpont for VAV4 [CFM]
%     vav1_d_sp = Meas_MPC(42):          Flow setpont for VAV1 [CFM]
%     vav2_d_sp = Meas_MPC(43):          Flow setpont for VAV2 [CFM]
%
% recv
%   = 0; normal mode
%   = 1; recovery mode (also assign ts_recv in this case)
% ts_recv
%   The timestep to recover to.
%   For example, if recv=1 and ts_recv=20, the simulation will not update
%   inputs to the DB when timestep<=20.
% coll_recv
%   The collection that the user wants to recover, name can be random if
%   recv = 0
%% Outputs
% ZoneInfo
% ={'T_out','Tdp_out','RH_out',...
%         'Qsen_z1_ahu1','Qlat_z1_ahu1','Tz_cspt_z1_ahu1','Tz_hspt_z1_ahu1','T_z1_ahu1','Tdp_z1_ahu1','w_z1_ahu1',...
%         'Qsen_z2_ahu1','Qlat_z2_ahu1','Tz_cspt_z2_ahu1','Tz_hspt_z2_ahu1','T_z2_ahu1','Tdp_z2_ahu1','w_z2_ahu1',...
%         'Qsen_z1_ahu2','Qlat_z1_ahu2','Tz_cspt_z1_ahu2','Tz_hspt_z1_ahu2','T_z1_ahu2','Tdp_z1_ahu2','w_z1_ahu2',...
%         'Qsen_z2_ahu2','Qlat_z2_ahu2','Tz_cspt_z2_ahu2','Tz_hspt_z2_ahu2','T_z2_ahu2','Tdp_z2_ahu2','w_z2_ahu2',...
%         'w_out'};
%   T_out: Outdoor air temperature [C]
%   Tdp_out: Outdoor air dewpoint temperature [C]
%   RH_out: Outdoor air relative humidity [%]
%   Qsen: Sensible load [W], positive = heating, negative = cooling
%   Qlat: Latent load [W], positive = humidify, negative = dehumidify
%   Tz_cspt: Zone cooling setpoint [C]
%   Tz_hspt: Zone heating setpoint [C]
%   T_z: (Simulated) Zone air temperature [C]
%   Tdp_z: Zone dewpoint temperature [C]
%   w_z: Zone humidity ratio [kgwater/kgair]
%   w_out: Outdoor air humidty ration [kgwater/kgair]
% CtrlSig
%   CtrlSig(1,1:20)
%     Only use the CtrlSig(2,i) value when CtrlSig(1,i)==1.
%   CtrlSig(2,1:20) = [sys_status,modulate_PID,T_chwst,DP_slSP,P_sp_ahu1,P_sp_ahu2,T_SA_ahu1,T_SA_ahu2,TS_mode,...
%    m_vav1_ahu1_sp,m_vav2_ahu1_sp,m_vav1_ahu2_sp,m_vav2_ahu2_sp,V_ahu1_sp,V_ahu2_sp,V_slSP_sp]
%     sys_status:       system status (0-off,1-on)
%     modulate_PID:     Activate modulate PID (0-off,1-on)
%     T_chwst:          chilled water temperature setpoint[°C]
%     DP_slSP:          chilled water secondary loop pressure setpoint[kPa]
%     P_sp_ahu1:        AHU1 supply air static pressure setpoint[Pa]
%     P_sp_ahu2:        AHU2 supply air static pressure setpoint[Pa]
%     T_SA_ahu1:        AHU1 supply air temperature setpoint [°C]
%     T_SA_ahu2:        AHU2 supply air temperature setpoint [°C]
%     TS_mode:          ice tank mode (0-bypass,1-discharge, 2-charge)
%     Vmin_vav1_ahu1:   minimum ventilation rate of ahu1-vav1(conference room mide 2) [CFM]
%     Vmin_vav2_ahu1:   minimum ventilation rate of ahu1-vav2(enclosed office mide 2) [CFM]
%     Vmin_vav1_ahu2:   minimum ventilation rate of ahu2-vav1(enclosed office mide 5) [CFM]
%     Vmin_vav2_ahu2:   minimum ventilation rate of ahu2-vav2(open office mide 1) [CFM]
%     m_vav1_ahu1_sp:   mass flow rate setpoint of ahu1-vav1
%     m_vav2_ahu1_sp:   mass flow rate setpoint of ahu1-vav2
%     m_vav1_ahu2_sp:   mass flow rate setpoint of ahu2-vav1
%     m_vav2_ahu2_sp:   mass flow rate setpoint of ahu2-vav2
%
%     V_ahu1_sp:        volume flow rate setpoint of ahu1 [CFM]
%     V_ahu2_sp:        volume flow rate setpoint of ahu2 [CFM]
%     V_slSP_sp:        volume flow rate setpoint of secondary loop chilled water [GPM]
%% Others
% startTime
%   EPlus simulation start time in seconds
%   For example, if user wants to simulate nth day of the year,
%   startTime = 86400*(n-1)
% stopTime
%   End time of the EPlus simulation.
%   For example, if user wants to simulate nth day of the year,
%   startTime = 86400*n
% stepsize
%   step size of each timestep (in seconds)
%   use to determine the associate time stamp
% GEB_step
%   number of timesteps between two GEB calls
% conn
%   DB connection cursor
% CollName
%   DB collection name. Automatic generated. Name constructed by the folder
%   names of the current and the upper two diectories, and date/time.
% ***Label
%   Label names for the data in DB
% timestep_GEB_start
%   timestep to start GEB computation
% timestep_GEB_read
%   timestep to read supervisory signals computed earlier

%% global variable
persistent recv ts_recv coll_recv startTime stopTime
persistent stepsize
persistent conn CollName DBName MeasLabel ZoneInfoLabel ZIFields CtrlSigLabel CSFields Meas_MPCLabel
persistent GEB_case Control_method TES Location STD Dense_Occupancy EGRSave_Occupant Season_type SimulinkName
persistent CollName_STD CollName_Location CollName_DenOcc startTime_forEnergyPlus Meas_received_Label
%% Initialization
if isempty(conn)
    % delete any existing parallel pool
    poolobj = gcp('nocreate');
    delete(poolobj);
    % read settings from file
    settings=readtable('settings.csv');
    recv = settings.recv(1);   % recovery mode
    ts_recv = settings.ts_recv(1); % time step to recover to
    coll_recv = settings.coll_recv{1}; % collection to recover
    if (recv>0.5 && strcmp(coll_recv,'current'))  % if current, use the COLL in DBLoc.mat
        coll_recv=load('DBLoc.mat').CollName;
    end
    % Test Location (1-Atlanta;2-Buffalo;3-NewYork;4-Tucson;5-ElPaso)
    Location = settings.Location(1);
    % Season type (1-typical winter;2-typical should;3-extreme summer;4-typical summer)
    Season_type = settings.SeasonType(1);
    % Based on location and simulated season type, determine simulation
    % time (day of year)
    DOY_Table=[28 119 189 238; 365 71 197 183; 30 289 191 177; 2 280 228 240; 9 107 170 203];
    DOY = DOY_Table(Location,Season_type);  % day of year
    startTime_forEnergyPlus=86400*(DOY-2);   % EPlus simulation start time in seconds
    startTime=86400*(DOY-1);                 % MongoDB and ControlModel start time in seconds
    stopTime=86400*DOY;     % EPlus simulation end time in seconds
    % GEB scenario to be tested (0-none,1-eff,2-shed,3-shift,4-modulate)
    GEB_case = settings.GEB_case(1);
    % GEB control method (0-rule based, 1-MPC)
    Control_method = settings.Control_method(1);
    % Test TES or not (0-no, 1-yes)
    TES = settings.TES(1);
    % STD (1-STD2004;2-STD2019)
    STD = settings.STD(1);
    % Dense occupancy or not
    Dense_Occupancy= settings.occ_dense(1);
    % Energy-saving occupants or not
    EGRSave_Occupant= settings.occ_energysaving(1);
    % parameters
    stepsize=settings.stepsize(1);    % step size of each timestep (in seconds)
    % directory
    par_dir = fileparts(strcat(pwd,'\callSim.m'));
    % add OBMsubfuntion to path
    addpath(strcat(par_dir,'\OBM'));
    % add Airflow ANN model to path
    addpath(strcat(par_dir,'\OBM\AirflowANNmodel'));
    % add DB function to path
    addpath(strcat(par_dir,'\DB'));
    % add virtual building to path
    addpath(strcat(par_dir,'\VB'));
    % add control models to path
    addpath(strcat(par_dir,'\CTRL'));
    % database name
    DBName = 'HILFT';
    % connect to the database (make sure the DB is created first)
    conn = mongo('localhost',27017,DBName);
    % collection name
    CollName_Location={'Atlanta';'Buffalo';'NewYork';'Tucson';'ElPaso'};
    CollName_GEBCase={'None';'Eff';'Shed';'Shif';'Modu'};
    CollName_Season={'TypWin';'TypShou';'ExtrmSum';'TypSum'};
    CollName_GEBControl={'RB';'MPC'};
    CollName_STD={'2004';'2019'};
    CollName_DenOcc={'TypOcc';'DenOcc'};
    CollName_EGROcc={'TypBehav';'EGRBehav'};
    CollName_TES={'NoTES';'TES'};
    %     parts=strsplit(par_dir, '\');
    %     CollName=[char(parts(end)),'_',char(datestr(now,'mmddyyyy')),...
    %         '_',char(datestr(now,'HHMMSS'))];
    CollName=[char(CollName_Location(Location)),...
        '_',char(CollName_GEBCase(GEB_case+1)),'_',char( CollName_Season(Season_type)),'_',...
        char(CollName_GEBControl(Control_method+1)),'_',char(CollName_STD(STD)),'_',...
        char(CollName_DenOcc(Dense_Occupancy+1)),'_',char(CollName_EGROcc(EGRSave_Occupant+1)),...
        '_',char(CollName_TES(TES+1)),'_',...
        char(datestr(now,'mmddyyyy')),'_',char(datestr(now,'HHMMSS'))];
    % recovery of an existing collection
    if (recv>0.5)
        CollName=coll_recv;
    end
    % save DBName and CollName to share with other models
    save DBLoc.mat DBName CollName
    % Labels
    MeasLabel={'m_sup_vav1_ahu1','T_sup_vav1_ahu1','w_sup_vav1_ahu1','T_z1_ahu1','w_z1_ahu1',...
        'm_sup_vav2_ahu1','T_sup_vav2_ahu1','w_sup_vav2_ahu1','T_z2_ahu1','w_z2_ahu1',...
        'm_sup_vav1_ahu2','T_sup_vav1_ahu2','w_sup_vav1_ahu2','T_z1_ahu2','w_z1_ahu2',...
        'm_sup_vav2_ahu2','T_sup_vav2_ahu2','w_sup_vav2_ahu2','T_z2_ahu2','w_z2_ahu2',...
        'W_ahu1','vfd_ahu1','d1_ahu1','d2_ahu1','rh1_ahu1','rh2_ahu1',...
        'P_sp_ahu1_cur','T_SA_ahu1_cur','V_cc_ahu1','Tin_cc_ahu1','Tout_cc_ahu1',...
        'W_ahu2','vfd_ahu2','d1_ahu2','d2_ahu2','rh1_ahu2','rh2_ahu2',...
        'P_sp_ahu2_cur','T_SA_ahu2_cur','V_cc_ahu2','Tin_cc_ahu2','Tout_cc_ahu2',...
        'W_CHW','m_CHW_pm','m_CHW_sl','T_CHW1','T_CHW2','T_CHW_TS','T_chwst_cur','DP_slSP_cur',...
        'TES_inventory','TES_status','T_out_emulated','T_return_ahu1','T_return_ahu2','Power_HVAC'};
    % Meas_recived (YC 2023/04/11)
    Meas_received_Label={'m_sup_vav1_ahu1','T_sup_vav1_ahu1','w_sup_vav1_ahu1','T_z1_ahu1','w_z1_ahu1',...
        'm_sup_vav2_ahu1','T_sup_vav2_ahu1','w_sup_vav2_ahu1','T_z2_ahu1','w_z2_ahu1',...
        'm_sup_vav1_ahu2','T_sup_vav1_ahu2','w_sup_vav1_ahu2','T_z1_ahu2','w_z1_ahu2',...
        'm_sup_vav2_ahu2','T_sup_vav2_ahu2','w_sup_vav2_ahu2','T_z2_ahu2','w_z2_ahu2',...
        'W_ahu1','vfd_ahu1','d1_ahu1','d2_ahu1','rh1_ahu1','rh2_ahu1',...
        'P_sp_ahu1_cur','T_SA_ahu1_cur','V_cc_ahu1','Tin_cc_ahu1','Tout_cc_ahu1',...
        'W_ahu2','vfd_ahu2','d1_ahu2','d2_ahu2','rh1_ahu2','rh2_ahu2',...
        'P_sp_ahu2_cur','T_SA_ahu2_cur','V_cc_ahu2','Tin_cc_ahu2','Tout_cc_ahu2',...
        'W_CHW','m_CHW_pm','m_CHW_sl','T_CHW1','T_CHW2','T_CHW_TS','T_chwst_cur','DP_slSP_cur',...
        'TES_inventory','TES_status','T_out_emulated','T_return_ahu1','T_return_ahu2','Power_HVAC'};
    Meas_MPCLabel={'ch1_c_in_rtd','ch1_c_out_rtd','ch1_f_c','ch1_e_in_rtd','ch1_e_out_rtd','ch1_f_e','ch1_power',...
        'ch2_c_in_rtd','ch2_c_out_rtd','ch2_f_c','ch2_e_in_rtd','ch2_e_out_rtd','ch2_f_e','ch2_power',...
        'ts_in_rtd','ts_out_rtd','ts_f','ts_meter',...
        'pl_f','sl_f','pump1_power','pump2_power','pump3_power',...
        'ahu1_cc_in_rtd','ahu1_cc_out_rtd','ahu1_f_cc','ahu1_in_rtd','ahu1_out_rtd','ahu1_f_ra','ahu1_f_sa','ahu1_fan_power',...
        'ahu2_cc_in_rtd','ahu2_cc_out_rtd','ahu2_f_cc','ahu2_in_rtd','ahu2_out_rtd','ahu2_f_ra','ahu2_f_sa','ahu2_fan_power',...
        'vav3_d_sp','vav4_d_sp','vav1_d_sp','vav2_d_sp'};
    ZoneInfoLabel={'T_out','Tdp_out','RH_out',...
        'Qsen_z1_ahu1','Qlat_z1_ahu1','Tz_cspt_z1_ahu1','Tz_hspt_z1_ahu1','T_z1_ahu1','Tdp_z1_ahu1','w_z1_ahu1',...
        'Qsen_z2_ahu1','Qlat_z2_ahu1','Tz_cspt_z2_ahu1','Tz_hspt_z2_ahu1','T_z2_ahu1','Tdp_z2_ahu1','w_z2_ahu1',...
        'Qsen_z1_ahu2','Qlat_z1_ahu2','Tz_cspt_z1_ahu2','Tz_hspt_z1_ahu2','T_z1_ahu2','Tdp_z1_ahu2','w_z1_ahu2',...
        'Qsen_z2_ahu2','Qlat_z2_ahu2','Tz_cspt_z2_ahu2','Tz_hspt_z2_ahu2','T_z2_ahu2','Tdp_z2_ahu2','w_z2_ahu2',...
        'w_out'};
    ZIFields=label2mongofield_find(ZoneInfoLabel);
    CtrlSigLabel={'sys_status','T_chwst','DP_slSP','P_sp_ahu1','P_sp_ahu2','T_SA_ahu1','T_SA_ahu2',...
        'TS_mode','Vmin_vav1_ahu1','Vmin_vav2_ahu1','Vmin_vav1_ahu2','Vmin_vav2_ahu2'....
        'm_vav1_ahu1_sp','m_vav2_ahu1_sp','m_vav1_ahu2_sp','m_vav2_ahu2_sp','Tz_cspt','Tz_hspt','V_ahu1_sp','V_ahu2_sp','V_slSP_sp'};
    CSFields=label2mongofield_find(CtrlSigLabel);
    if (recv<0.5) % start a new collection in normal mode
        % create collection
        if any(strcmp(CollName,conn.CollectionNames))
            % drop the old collection
            dropCollection(conn,CollName);
        end
        createCollection(conn,CollName);
    end
    % insert recovery settings to DB
    remove(conn,CollName,'{"DocType":"RecvSettings"}');
    RecvDoc.DocType="RecvSettings";
    RecvDoc.recv=recv;
    RecvDoc.time_recv=startTime+ts_recv*60;
    insert(conn,CollName,RecvDoc);
end

if timestep<0
    %% for thie period before the tested day (YC 02/18/2022)
    % only storage the Measurement and ControlSignal with TES_Measurements
    % and TES_SupvCtrlSig as DocType
    MeasDoc.DocType='TES_Measurements';
    MeasDoc.HardwareTime = HardwareTime;
    MeasDoc.Timestep=timestep;
    MeasDoc.Time=startTime+timestep*60;
    insert(conn,CollName,MeasDoc);
    Mquery=mongo2mongofiled_upset(MeasLabel,...
        Meas);
    update(conn,CollName,['{"Timestep":',num2str(timestep),...
        ',"DocType":"TES_Measurements"}'],Mquery);
    % determine ice tank control signal and push to DB
    TES_inventory=Meas(51);
    TS_mode = 0;
    if TES_inventory<85.0
        TS_mode=2;
    end
    CtrlSig=zeros(2,17);
    CtrlSig(1,9)=1;
    CtrlSig(2,9)=TS_mode;
    CtrlSigDoc.DocType='TES_SupvCtrlSig';
    CtrlSigDoc.HardwareTime = HardwareTime;
    CtrlSigDoc.Timestep=timestep;
    CtrlSigDoc.Time=startTime+timestep*60;
    CtrlSigDoc.TS_mode = CtrlSig(:,9);
    insert(conn,CollName,CtrlSigDoc);
    % make a blank metrix to output ZoneInfo
    ZoneInfo=zeros(1,length(ZoneInfoLabel));
else
    %% Push data to DB
    if (recv<0.5 || timestep>ts_recv)
        % based on the system status to adjust the Meas
        Meas_received=Meas;
        if timestep==0
            Meas(1)=0;
            Meas(6)=0;
            Meas(11)=0;
            Meas(16)=0;
        elseif timestep<361
            SupvCtrlSig_LastTimestep=find(conn,CollName,'Query',['{"Timestep":',...
                num2str(timestep-1),',"DocType":"SupvCtrlSig"}']);
            Sys_Status_LastTime=SupvCtrlSig_LastTimestep.sys_status(2,1);
            if Sys_Status_LastTime==0
                Meas(1)=0;
                Meas(6)=0;
                Meas(11)=0;
                Meas(16)=0;
            end
        end
        % remove all existing doc for the current timestep in recovery mode
        if (recv>0.5)
            remove(conn,CollName,['{"Timestep":',num2str(timestep),'}']);
        end
        % create doc for crucial simulated data
        DataDoc.DocType='SimData';
        DataDoc.Timestep=timestep;
        DataDoc.Time=startTime+timestep*60;
        insert(conn,CollName,DataDoc);
        % push Meas to DB
        MeasDoc.DocType='Measurements';
        MeasDoc.HardwareTime = HardwareTime;
        MeasDoc.Timestep=timestep;
        MeasDoc.Time=startTime+timestep*60;
        insert(conn,CollName,MeasDoc);
        Mquery=mongo2mongofiled_upset(MeasLabel,...
            Meas);
        update(conn,CollName,['{"Timestep":',num2str(timestep),...
            ',"DocType":"Measurements"}'],Mquery);
        % push Meas_received to DB (YC 2023/04/11)
        MeasDoc.DocType='Measurements_received';
        MeasDoc.HardwareTime = HardwareTime;
        MeasDoc.Timestep=timestep;
        MeasDoc.Time=startTime+timestep*60;
        insert(conn,CollName,MeasDoc);
        Mquery=mongo2mongofiled_upset(Meas_received_Label,...
            Meas_received);
        update(conn,CollName,['{"Timestep":',num2str(timestep),...
            ',"DocType":"Measurements_received"}'],Mquery);        
        % push Meas_MPC to DB (YC 2022/09/20)
        Meas_MPCDoc.DocType='Measurements_MPC';
        Meas_MPCDoc.HardwareTime = HardwareTime;
        Meas_MPCDoc.Timestep=timestep;
        Meas_MPCDoc.Time=startTime+timestep*60;
        insert(conn,CollName,Meas_MPCDoc);
        Mquery=mongo2mongofiled_upset(Meas_MPCLabel,...
            Meas_MPC);
        update(conn,CollName,['{"Timestep":',num2str(timestep),...
            ',"DocType":"Measurements_MPC"}'],Mquery);
        % run GEB control module
        CtrlSig = Control_Model(startTime,timestep,Season_type,GEB_case,Control_method,TES,Meas,STD,Dense_Occupancy,conn,CollName);
    else
        % Get CtrlSig from DB in recovery mode
        CtrlSig=zeros(2,length(CtrlSigLabel));
        ret_CS=find(conn,CollName,'Query',['{"Timestep":',num2str(timestep),...
            ',"DocType":"SupvCtrlSig"}'],'Projection',CSFields);
        for i=1:length(CtrlSigLabel)
            CtrlSig(:,i)=ret_CS.(char(CtrlSigLabel(i)));
        end
    end
    
    %% run virtual building model
    if timestep==0
        % open Simulink
        % Simulink file name
        if Location==4  % Tucson
            if Season_type==1 || Season_type==4
                SimulinkName=['FourZones_STD',char(CollName_STD(STD)),'_',...
                    char(CollName_Location(Location)),'2019Year_',char(CollName_DenOcc(Dense_Occupancy+1)),'.slx'];
            elseif Season_type==2
                SimulinkName=['FourZones_STD',char(CollName_STD(STD)),'_',...
                    char(CollName_Location(Location)),'2015Year_',char(CollName_DenOcc(Dense_Occupancy+1)),'.slx'];
            elseif Season_type==3
                SimulinkName=['FourZones_STD',char(CollName_STD(STD)),'_',...
                    char(CollName_Location(Location)),'2017Year_',char(CollName_DenOcc(Dense_Occupancy+1)),'.slx'];
            end
        elseif Location==5  % ElPaso
            if Season_type==4
                SimulinkName=['FourZones_STD',char(CollName_STD(STD)),'_',...
                    char(CollName_Location(Location)),'2015Year_',char(CollName_DenOcc(Dense_Occupancy+1)),'.slx'];
            else
                SimulinkName=['FourZones_STD',char(CollName_STD(STD)),'_',...
                    char(CollName_Location(Location)),'2013Year_',char(CollName_DenOcc(Dense_Occupancy+1)),'.slx'];
            end
        else
            SimulinkName=['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1)),'.slx'];
        end
        open_system(SimulinkName);
        % set Simulink start time and stop time at the initial call
        set_param(['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1))],'StartTime',string(startTime_forEnergyPlus),'StopTime',string(stopTime));
        % start Simulink
        set_param(['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1))],'SimulationCommand','start');
        for i_firstday=0:(1440-1)
            set_param(['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1))],'SimulationCommand','pause');
            set_param(['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1))],'SimulationCommand','continue');
        end
    else
        % continue Simulink
        set_param(['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1))],'SimulationCommand','continue');
    end
    % pause Simulink
    set_param(['FourZones_STD',char(CollName_STD(STD)),'_',...
                char(CollName_Location(Location)),'_',char(CollName_DenOcc(Dense_Occupancy+1))],'SimulationCommand','pause');
    %% Get ZoneInfo from DB
    ZoneInfo=zeros(1,length(ZoneInfoLabel));
    ret=find(conn,CollName,'Query',['{"Timestep":',num2str(timestep),...
        ',"DocType":"SimData"}'],'Projection',ZIFields);
    for i=1:length(ZoneInfoLabel)
        ZoneInfo(i)=ret.(char(ZoneInfoLabel(i)));
    end
    %% Finalization
    if (timestep==86400/stepsize)
        set_param(bdroot,'SimulationCommand','stop');
        save_system(SimulinkName);
        close_system(SimulinkName);
        poolobj = gcp('nocreate');
        delete(poolobj);
    end
end
end