function CtrlSig = Control_Model(startTime,timestep,Season_type,GEB_case,Control_method,TES,Meas,STD,Dense_Occupancy,conn,CollName)
%% inputs
% startTime: start time in seconds of the tested DOY
% timestep: current timestep
% Season_type: used to determine whether daylight saving (1-typical winter;2-typical shoulder;3-extreme summer;4-typical summer)
% TES: whether to test ice tank (0-no, 1-yes)
% GEB_case: GEB scenario to be tested (0-none,1-eff,2-shed,3-shift,4-modulate)
% GEB_control: GEB control method (0-rule based, 1-MPC)
% conn: database connection cursor
% CollName: database collection name
% STD: building code standard (1-STD2004;2-STD2019)
% Dense_Occupancy: 0-typical occupancy; 1-dense occupancy
% Meas:
%     m_sup_vav1_ahu1 = Meas(1) :   vav discharge air mass flow rate of zone 1 served by AHU1 [kg/s]
%     T_sup_vav1_ahu1 = Meas(2) :   vav discharge air temperature of zone 1 served by AHU1 [°C]
%     w_sup_vav1_ahu1 = Meas(3) :   vav discharge air humidity ratio of zone 1 served by AHU1 [kg/kg]
%     T_z1_ahu1 = Meas(4) :         zone air temperature of zone 1 served by AHU1 [°C]
%     w_z1_ahu1 = Meas(5) :         humidity ratio of zone 1 served by AHU1 [kg/kg]
%     m_sup_vav2_ahu1 = Meas(6) :   vav discharge air mass flow rate of zone 2 served by AHU1 [kg/s]
%     T_sup_vav2_ahu1 = Meas(7) :   vav discharge air temperature of zone 2 served by AHU1 [°C]
%     w_sup_vav2_ahu1 = Meas(8) :   vav humidity ratio of zone 2 served by AHU1 [kg/kg]
%     T_z2_ahu1 = Meas(9) :         zone air temperature of zone 2 served by AHU1 [°C]
%     w_z2_ahu1 = Meas(10) :        humidity ratio of zone 2 served by AHU1 [kg/kg]
%     m_sup_vav1_ahu2 = Meas(11) :  vav discharge air mass flow rate of zone 1 served by AHU2 [kg/s]
%     T_sup_vav1_ahu2 = Meas(12) :  vav discharge air temperature of zone 1 served by AHU2 [°C]
%     w_sup_vav1_ahu2 = Meas(13) :  vav humidity ratio of zone 1 served by AHU2 [kg/kg]
%     T_z1_ahu2 = Meas(14) :        zone air temperature of zone 1 served by AHU2 [°C]
%     w_z1_ahu2 = Meas(15) :        humidity ratio of zone 1 served by AHU2 [kg/kg]
%     m_sup_vav2_ahu2 = Meas(16) :  vav discharge air mass flow rate of zone 2 served by AHU2 [kg/s]
%     T_sup_vav2_ahu2 = Meas(17) :  vav discharge air temperature of zone 2 served by AHU2 [°C]
%     w_sup_vav2_ahu2 = Meas(18) :  vav humidity ratio of zone 2 served by AHU2 [kg/kg]
%     T_z2_ahu2 = Meas(19) :        zone air temperature of zone 2 served by AHU2 [°C]
%     w_z2_ahu2 = Meas(20) :        humidity ratio of zone 2 served by AHU2 [kg/kg]
%     W_ahu1 = Meas(21) :           AHU1 power [W]
%     vfd_ahu1 = Meas(22) :         AHU1 fan speed [Hz]
%     d1_ahu1 = Meas(23) :          vav damper position of zone 1 served by AHU1 [V]
%     d2_ahu1 = Meas(24) :          vav damper position of zone 2 served by AHU1 [V]
%     rh1_ahu1 = Meas(25) :         reheat coil status (0 or 1) of zone 1 served by AHU1
%     rh2_ahu1 = Meas(26) :         reheat coil status (0 or 1) of zone 2 served by AHU1
%     P_sp_ahu1_cur = Meas(27) :    AHU1 current static pressure measurement [Pa]
%     T_SA_ahu1_cur = Meas(28) :    AHU1 current supply air temperature measurement [°C]
%     V_cc_ahu1 = Meas(29) :        AHU1 Cooling coil valve position [V]
%     Tin_cc_ahu1 = Meas(30) :      AHU1 Cooling coil inlet temperature [°C]
%     Tout_cc_ahu1 = Meas(31) :     AHU1 Cooling coil outlet temperature [°C]
%     W_ahu2 = Meas(32) :           AHU2 power [W]
%     vfd_ahu2 = Meas(33) :         AHU2 fan speed [Hz]
%     d1_ahu2 = Meas(34) :          vav damper position of zone 1 served by AHU2 [V]
%     d2_ahu2 = Meas(35) :          vav damper position of zone 2 served by AHU2 [V]
%     rh1_ahu2 = Meas(36) :         reheat coil status (0 or 1) of zone 1 served by AHU2
%     rh2_ahu2 = Meas(37) :         reheat coil status (0 or 1) of zone 2 served by AHU2
%     P_sp_ahu2_cur = Meas(38) :    AHU2 current static pressure measurement [Pa]
%     T_SA_ahu2_cur = Meas(39) :    AHU2 current supply air temperature measurement [°C]
%     V_cc_ahu2 = Meas(40) :        AHU2 Cooling coil valve position [V]
%     Tin_cc_ahu2 = Meas(41) :      AHU2 Cooling coil inlet temperature [°C]
%     Tout_cc_ahu2 = Meas(42) :     AHU2 Cooling coil outlet temperature [°C]
%     W_CHW = Meas(43) :            chiller power [W]
%     m_CHW_pm = Meas(44) :         primary chilled water pump flow rate [kg/s]
%     m_CHW_sl = Meas(45) :         secondary chilled water pump flow rate [kg/s]
%     T_CHW1 = Meas(46) :           chiller1 chilled water supply temperature [°C]
%     T_CHW2 = Meas(47) :           chiller2 chilled water supply temperature [°C]
%     T_CHW_TS = Meas(48) :         ice tank chilled water supply temperature [°C]
%     T_chwst_cur = Meas(49) :      current chilled water temperature measurement[°C]
%     DP_slSP_cur = Meas(50);       current chilled water secondary loop pressure measurement[kPa]
%     TES_inventory = Meas(51);     current ice tank inventory level (0 to 1)
%     TES_status = Meas(52);        current ice tank status (0-charing/discharging,1-fully discharged,2-fully charged)
%     T_out_emulated = Meas(53);    emulated outdoor air temperature [°C]
%     T_return_ahu1 = Meas(54);     return air temperature of AHU1 [°C]
%     T_return_ahu2 = Meas(55);     return air temperature of AHU2 [°C]
%     Power_HVAC_electric = Meas(56);     Total electric power of HVAC system including primary/secondary system [kW]
%% outputs
% CtrlSig(1,1:20)
%     Take the CtrlSig(2,i) setpoint only when CtrlSig(1,i)==1
% CtrlSig(2,1:20) = [sys_status,modulate_PID,T_chwst,DP_slSP,P_sp_ahu1,P_sp_ahu2,T_SA_ahu1,T_SA_ahu2,TS_mode,...
%    m_vav1_ahu1_sp,m_vav2_ahu1_sp,m_vav1_ahu2_sp,m_vav2_ahu2_sp,V_ahu1_sp,V_ahu2_sp,V_slSP_sp]
%     sys_status:       system status (0-off,1-on)
%     modulate_PID:     Activate modulate PID (0-off,1-on)
%     T_chwst:          chilled water temperature setpoint[°C]
%     DP_slSP:          chilled water secondary loop pressure setpoint[kPa]
%     P_sp_ahu1:        AHU1 supply air static pressure setpoint[Pa]
%     P_sp_ahu2:        AHU2 supply air static pressure setpoint[Pa]
%     T_SA_ahu1:        AHU1 supply air temperature setpoint [°C]
%     T_SA_ahu2:        AHU2 supply air temperature setpoint [°C]
%     TS_mode:          ice tank mode (0-by pass,1-discharge, 2-charge)
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
%% others
%     chMode: chiller controller mode, 0-Manual, 1-Auto
%     dpMode: secondary loop controller, 0-Manual, 1-Auto
%% Main program
%% read measurements
% zone-level measurements
m_sup_vav1_ahu1 = Meas(1);
T_sup_vav1_ahu1 = Meas(2);
w_sup_vav1_ahu1 = Meas(3);
T_z1_ahu1 = Meas(4);
w_z1_ahu1 = Meas(5);
m_sup_vav2_ahu1 = Meas(6);
T_sup_vav2_ahu1 = Meas(7);
w_sup_vav2_ahu1 = Meas(8);
T_z2_ahu1 = Meas(9);
w_z2_ahu1 = Meas(10);
m_sup_vav1_ahu2 = Meas(11);
T_sup_vav1_ahu2 = Meas(12);
w_sup_vav1_ahu2 = Meas(13);
T_z1_ahu2 = Meas(14);
w_z1_ahu2 = Meas(15);
m_sup_vav2_ahu2 = Meas(16);
T_sup_vav2_ahu2 = Meas(17);
w_sup_vav2_ahu2 = Meas(18);
T_z2_ahu2 = Meas(19);
w_z2_ahu2 = Meas(20);
% AHU1 measurements
W_ahu1 = Meas(21);
vfd_ahu1 = Meas(22);
d1_ahu1 = Meas(23);
d2_ahu1 = Meas(24);
rh1_ahu1 = Meas(25);
rh2_ahu1 = Meas(26);
P_sp_ahu1_cur = Meas(27);
T_SA_ahu1_cur = Meas(28);
V_cc_ahu1 = Meas(29);
Tin_cc_ahu1 = Meas(30);
Tout_cc_ahu1 = Meas(31);
% AHU2 measurements
W_ahu2 = Meas(32);
vfd_ahu2 = Meas(33);
d1_ahu2 = Meas(34);
d2_ahu2 = Meas(35);
rh1_ahu2 = Meas(36);
rh2_ahu2 = Meas(37);
P_sp_ahu2_cur = Meas(38);
T_SA_ahu2_cur = Meas(39);
V_cc_ahu2 = Meas(40);
Tin_cc_ahu2 = Meas(41);
Tout_cc_ahu2 = Meas(42);
% chill water measurements
chMode = 2; % 1-Manual; 2-Auto
dpMode = 2; % 1-Manual; 2-Auto
W_chw = Meas(43);
m_chw_pm = Meas(44);
m_chw_sl = Meas(45);
T_chw1 = Meas(46);
T_chw2 = Meas(47);
T_chw_TS = Meas(48);
T_chwst_cur = Meas(49);
DP_slSP_cur = Meas(50);
% ice tank measurements
TES_inventory = Meas(51);
TES_status = Meas(52);
% Emulated outdoor air temperature
T_out_emulated = Meas(53);
% Return air temperature for AHU1 and 2
T_return_ahu1 = Meas(54);
T_return_ahu2 = Meas(55);
%% persistent occupancy schedule
persistent OccupancySchedule T_out_Label T_out_Fields T_out PeakPeriod CollNmae_sparate Location Location_Num
persistent timestep_GEB_start timestep_GEB_read GEB_background GEB_step CtrlSig_GEB SCS_query
%% initiate DB connection and get T_out from SimData
if isempty(T_out_Label)
    % query command
    T_out_Label={'T_out'};
    T_out_Fields=label2mongofield_find(T_out_Label);
    % initialize T_out
    T_out=zeros(1,length(T_out_Label));
    
    % GEB settings (YC 2022/09/12)
    if Control_method==1
        par_dir = fileparts(strcat(pwd,'\callSim.m'));
        addpath(strcat(par_dir,'\CTRL\MPC'));
        addpath(fullfile(par_dir, '\CTRL\MPC\casadi-windows-v3.5.5')); % add casadi to path
        addpath(fullfile(par_dir, '\CTRL\MPC\load-shifting')); % add casadi to path
        addpath('C:\gurobi1000\win64\matlab') % add gurobi matlab api to matlab
        timestep_GEB_start = (15:15:90*15);
        timestep_GEB_read = ((15+15):15:91*15);
        parpool('local',2);
        GEB_module = Simulink.SimulationInput('GEB');
        GEB_step=15;  % number of timesteps between two GEB calls
        CtrlSig_GEB=zeros(1,7);
    end
end
if timestep==0
    T_out=T_out_emulated;
else
clock=startTime+(timestep-1)*60;
ret=find(conn,CollName,'Query',['{"Time":',num2str(clock),...
    ',"DocType":"SimData"}'],'Projection',T_out_Fields);
T_out=ret.(char(T_out_Label(1)));%(end);
end

%% determine whether daylight saving
% Occupancy period  is from 7:40 to 19:40 (standard time)
OccupiedPeriod=[7*60+40 19*60+40];
if Season_type==1 % typical winter, no daylight saving. clock time=standard time
    OccupiedPeriod=OccupiedPeriod;
    DaylightSaving=0;
    OccTimestep=timestep;
else % for other test date, it is winin daylight saving period, clok time=standard time - 60min
    OccupiedPeriod=OccupiedPeriod-60;
    DaylightSaving=1;
    OccTimestep=timestep+60;   % OccTimesetp is used to locate the occupant schedule.
    if OccTimestep>1440
        OccTimestep=OccTimestep-1440;
    end
end
%% determine system operation
% The system operation hours is 7:00-21:00 (standard time) which is the occupied time of simulated zone 
if (timestep>(OccupiedPeriod(1)-40)) && (timestep<=(OccupiedPeriod(2)+80))
    sys_status = 1;
else
    sys_status = 0;
end
% determine whether occupied 
if (timestep>OccupiedPeriod(1)) && (timestep<=OccupiedPeriod(2))
    Occupied = 1;
else
    Occupied = 0;
end
%% set to default setpoint
% which may be reset by GEB control
[T_chwst,DP_slSP,P_sp_ahu1,P_sp_ahu2,T_SA_ahu1,T_SA_ahu2,Tz_hspt,Tz_cspt]=DefaultSettingIBAL(sys_status,Season_type,Occupied);
%% determine setpoints
% initialized vav mass flow rate setpoints. will only be used when
% GEB_control==1 (MPC mode)
TS_mode = 0;
Vmin_vav1_ahu1 = 0;
Vmin_vav2_ahu1 = 0;
Vmin_vav1_ahu2 = 0;
Vmin_vav2_ahu2 = 0;
m_vav1_ahu1_sp = 0;
m_vav2_ahu1_sp = 0;
m_vav1_ahu2_sp = 0;
m_vav2_ahu2_sp = 0;
% initialized the peak period for four location and three seasons
if isempty(PeakPeriod)
    PeakPeriod=cell(4,3);
    PeakPeriod{1,1}=[99 99];  % Atlanta typical shoulder
    PeakPeriod{1,2}=[14 19];  % Atlanta extreme summer
    PeakPeriod{1,3}=[14 19];  % Atlanta typical summer
    PeakPeriod{2,1}=[99 99];
    PeakPeriod{2,2}=[11 17];
    PeakPeriod{2,3}=[11 17];
    PeakPeriod{3,1}=[12 20];
    PeakPeriod{3,2}=[12 20];
    PeakPeriod{3,3}=[12 20];
    PeakPeriod{4,1}=[6 10 17 21];
    PeakPeriod{4,2}=[14 20];
    PeakPeriod{4,3}=[14 20];
    CollNmae_sparate=strsplit(CollName,'_');
    Location=CollNmae_sparate{1};
    if strcmp(Location,'Atlanta')
        Location_Num=1;
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_a'));
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_a\low-level'));
    elseif strcmp(Location,'Buffalo')
        Location_Num=2;
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_b'));
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_b\low-level'));
    elseif strcmp(Location,'NewYork')
        Location_Num=3;
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_ny'));
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_ny\low-level'));
    elseif strcmp(Location,'Tucson')
        Location_Num=4;
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_t'));
        addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_t\low-level'));
    end
    
end

switch Control_method
    case 0  % Rule-based control
        % determine zone-level setpoints
        %!!!!!!!!!! need to be modified after utility programs are decided
        modulate_PID = 0;
        %         Tz_hspt = 68;
        %         Tz_cspt = 72;
        if (GEB_case>0) % for all GEB cases
            % GEB_case==1,2,3, use different zone temperature setpoint
            if (GEB_case==1)
                if (timestep>(12-DaylightSaving)*60 && timestep<=OccupiedPeriod(2))
                    TS_mode = 1*TES;
                elseif timestep<= OccupiedPeriod(1)
                    TS_mode = 2*TES;
                else % after the operation hours, will not charge the TS
                    TS_mode = 0;
                end
            elseif (GEB_case==2)
                if Location_Num==4 && Season_type==2
                    shed_start_1=(PeakPeriod{Location_Num,(Season_type-1)}(1)-DaylightSaving)*60;
                    shed_end_1=(PeakPeriod{Location_Num,(Season_type-1)}(2)-DaylightSaving)*60;
                    shed_start_2=(PeakPeriod{Location_Num,(Season_type-1)}(3)-DaylightSaving)*60;
                    shed_end_2=(PeakPeriod{Location_Num,(Season_type-1)}(4)-DaylightSaving)*60;
                    if (sys_status>0)
                        if (timestep>(shed_start_1-2*60) && timestep<=shed_start_1)
                            TS_mode = 2*TES;
                        elseif (timestep>shed_start_1 && timestep<=shed_end_1) ||...
                                (timestep>shed_start_2 && timestep<=shed_end_2)
                            Tz_cspt = 80;
                            Tz_hspt = 66;  % both setpoint will be reset (YC 2022/05/05)
                            TS_mode = 1*TES;
                        else
                            TS_mode = 0;
                        end
                    else
                        TS_mode = 0;
                    end
                else
                    shed_start=(PeakPeriod{Location_Num,(Season_type-1)}(1)-DaylightSaving)*60;
                    shed_end=(PeakPeriod{Location_Num,(Season_type-1)}(2)-DaylightSaving)*60;
                    if (sys_status>0)
                        if (timestep>(shed_start-2*60) && timestep<=shed_start)
                            TS_mode = 2*TES;
                        elseif (timestep>shed_start && timestep<=shed_end)
                            Tz_cspt = 80;
                            Tz_hspt = 66;  
                            TS_mode = 1*TES;
                        else
                            TS_mode = 0;
                        end
                    else
                        TS_mode = 0;
                    end
                end
            elseif (GEB_case==3)
                % rewrite for ice tank cases (ZC 02/16/2022)
                if logical(TES)
                    % if ice tank is tested, use the same temperature
                    % setpoint as the efficiency cases
                    Tz_cspt = 78;
                    % set ice tank to standby mode by default
                    TS_mode = 0;
                    % discharge during peak until it reaches 45% ice
                    % update the peak schedule (YC 02/16/2022)
                    if Location_Num==4 && Season_type==2
                        shed_start_1=(PeakPeriod{Location_Num,(Season_type-1)}(1)-DaylightSaving)*60;
                        shed_end_1=(PeakPeriod{Location_Num,(Season_type-1)}(2)-DaylightSaving)*60;
                        shed_start_2=(PeakPeriod{Location_Num,(Season_type-1)}(3)-DaylightSaving)*60;
                        shed_end_2=(PeakPeriod{Location_Num,(Season_type-1)}(4)-DaylightSaving)*60;
                        if sys_status==1 && ((timestep>shed_start_1 && timestep<=shed_end_1 && TES_inventory>45.0) ||...
                                (timestep>shed_start_2 && timestep<=shed_end_2 && TES_inventory>45.0))
                            TS_mode = 1;
                        end
                    else
                        shed_start=(PeakPeriod{Location_Num,(Season_type-1)}(1)-DaylightSaving)*60;
                        shed_end=(PeakPeriod{Location_Num,(Season_type-1)}(2)-DaylightSaving)*60;
                        if sys_status==1 && (timestep>shed_start && timestep<=shed_end && TES_inventory>45.0)
                            TS_mode = 1;
                        end
                    end
                    % charge during unoccupied until it reaches 85% ice
                    if (timestep<60*(12-DaylightSaving) && sys_status==0 && TES_inventory<85.0)
                        TS_mode = 2;
                    end
                else
                    % load shifting throught zone temperature setpoint
                    TS_mode = 0;  % no use ice tank
                    Precool_spt=75;  %[F]
                    Precool_duration=3;  %[h]
                    if Location_Num==4 && Season_type==2
                        shed_start_1=(PeakPeriod{Location_Num,(Season_type-1)}(1)-DaylightSaving)*60;
                        shed_end_1=(PeakPeriod{Location_Num,(Season_type-1)}(2)-DaylightSaving)*60;
                        shed_start_2=(PeakPeriod{Location_Num,(Season_type-1)}(3)-DaylightSaving)*60;
                        shed_end_2=(PeakPeriod{Location_Num,(Season_type-1)}(4)-DaylightSaving)*60;
                        if (sys_status>0)
                            if ((timestep>(shed_start_1-Precool_duration*60) && timestep<=shed_start_1)) ||...
                                ((timestep>(shed_start_2-Precool_duration*60) && timestep<=shed_start_2))
                                Tz_cspt = Precool_spt;
                            elseif (timestep>shed_start_1 && timestep<=shed_end_1) ||...
                                    (timestep>shed_start_2 && timestep<=shed_end_2)
                                Tz_cspt = 80;
                            end
                        end
                    else
                        shed_start=(PeakPeriod{Location_Num,(Season_type-1)}(1)-DaylightSaving)*60;
                        shed_end=(PeakPeriod{Location_Num,(Season_type-1)}(2)-DaylightSaving)*60;
                        if (sys_status>0)
                            if (timestep>(shed_start-Precool_duration*60) && timestep<=shed_start)
                                Tz_cspt = Precool_spt;
                            elseif (timestep>shed_start && timestep<=shed_end)
                                Tz_cspt = 80;
                            end
                        end
                    end
                end
            elseif (GEB_case==4)
                if (timestep>(12-DaylightSaving)*60 && timestep<=OccupiedPeriod(2))
                    TS_mode = 1*TES;
                elseif timestep<= OccupiedPeriod(1)
                    TS_mode = 2*TES;
                else % after the operation hours, will not charge the TS
                    TS_mode = 0;
                end
                modulate_PID = 1;   % activate modulate PID
            end
            
            % commet by Yicheng 2022/03/03
%             % when ice tank need to discharge but its current status is
%             % fully dischared Or it need to be charged but has been fully
%             % charged, set the the control signal for ice tank to "bypass"
%             if (TS_mode==1 && TES_status==1) || (TS_mode==2 && TES_status==2)
%                 TS_mode=0;
%             end
            
            if sys_status==1
                if isempty(OccupancySchedule)
                    load('OccSche.mat')
                end
                % determine system-level setpoints
                if STD ==1      % typical control
                    P_sp_ahu1 = RB_SAP_RESET_ahu1(W_ahu1,d1_ahu1,d2_ahu1,P_sp_ahu1_cur);
                    P_sp_ahu2 = RB_SAP_RESET_ahu2(W_ahu2,d1_ahu2,d2_ahu2,P_sp_ahu2_cur);
                    [T_chwst] = RB_T_chwst_RESET_typical(T_out);
                    %P_sp_ahu1 = RB_SAP_RESET_ahu1_typical(W_ahu1,d1_ahu1,d2_ahu1,P_sp_ahu1_cur,T_z1_ahu1,T_z2_ahu1,(Tz_cspt-32)/1.8);
                    %P_sp_ahu2 = RB_SAP_RESET_ahu2_typical(W_ahu2,d1_ahu2,d2_ahu2,P_sp_ahu2_cur,T_z1_ahu2,T_z2_ahu2,(Tz_cspt-32)/1.8);
                    %T_SA_ahu1 = RB_SAT_RESET_ahu1_typical(d1_ahu1,d2_ahu1,rh1_ahu1,rh2_ahu1,V_cc_ahu1,vfd_ahu1,T_SA_ahu1_cur,Tz_cspt);
                    %T_SA_ahu2 = RB_SAT_RESET_ahu2_typical(d1_ahu2,d2_ahu2,rh1_ahu2,rh2_ahu2,V_cc_ahu2,vfd_ahu2,T_SA_ahu2_cur,Tz_cspt);
                    Vmin_vav1_ahu1=Vmin_RESET_z1(1,OccupancySchedule(OccTimestep,1),STD,Dense_Occupancy);   % Vmin reset for conference room
                    Vmin_vav2_ahu1=Vmin_RESET_z2(2,OccupancySchedule(OccTimestep,2),STD,Dense_Occupancy); % Vmin reset for enclosed office 2
                    Vmin_vav1_ahu2=Vmin_RESET_z3(3,OccupancySchedule(OccTimestep,3),STD,Dense_Occupancy); % Vmin reset for enclosed office 5
                    Vmin_vav2_ahu2=Vmin_RESET_z4(4,OccupancySchedule(OccTimestep,4),STD,Dense_Occupancy);   % Vmin reset for open office
                elseif STD ==2   % high-performance control
                    P_sp_ahu1 = RB_SAP_RESET_ahu1(W_ahu1,d1_ahu1,d2_ahu1,P_sp_ahu1_cur);
                    P_sp_ahu2 = RB_SAP_RESET_ahu2(W_ahu2,d1_ahu2,d2_ahu2,P_sp_ahu2_cur);
                    T_SA_ahu1 = RB_SAT_RESET_ahu1(d1_ahu1,d2_ahu1,rh1_ahu1,rh2_ahu1,...
                        V_cc_ahu1,vfd_ahu1,T_SA_ahu1_cur);
                    T_SA_ahu2 = RB_SAT_RESET_ahu2(d1_ahu2,d2_ahu2,rh1_ahu2,rh2_ahu2,...
                        V_cc_ahu2,vfd_ahu2,T_SA_ahu2_cur);
                    [T_chwst,DP_slSP] = RB_CHW_RESET(chMode,dpMode,...
                        T_chwst_cur,DP_slSP_cur,W_chw,V_cc_ahu1,V_cc_ahu2);
                    Vmin_vav1_ahu1=Vmin_RESET_z1(1,OccupancySchedule(OccTimestep,1),STD,Dense_Occupancy);   % Vmin reset for conference room
                    Vmin_vav2_ahu1=Vmin_RESET_z2(2,OccupancySchedule(OccTimestep,2),STD,Dense_Occupancy); % Vmin reset for enclosed office 2
                    Vmin_vav1_ahu2=Vmin_RESET_z3(3,OccupancySchedule(OccTimestep,3),STD,Dense_Occupancy); % Vmin reset for enclosed office 5
                    Vmin_vav2_ahu2=Vmin_RESET_z4(4,OccupancySchedule(OccTimestep,4),STD,Dense_Occupancy);   % Vmin reset for open office
                end
            else
                [T_chwst,DP_slSP,P_sp_ahu1,P_sp_ahu2,T_SA_ahu1,T_SA_ahu2,Tz_hspt,Tz_cspt]=DefaultSettingIBAL(sys_status,Season_type,Occupied);
                Vmin_vav1_ahu1=0;
                Vmin_vav2_ahu1=0;
                Vmin_vav1_ahu2=0;
                Vmin_vav2_ahu2=0;
            end
        else
            [T_chwst,DP_slSP,P_sp_ahu1,P_sp_ahu2,T_SA_ahu1,T_SA_ahu2,Tz_hspt,Tz_cspt]=DefaultSettingIBAL(sys_status,Season_type,Occupied);
            Vmin_vav1_ahu1=Vmin_RESET_z1(1,OccupancySchedule(OccTimestep,1),STD,Dense_Occupancy);   % Vmin reset for conference room
            Vmin_vav2_ahu1=Vmin_RESET_z2(2,OccupancySchedule(OccTimestep,2),STD,Dense_Occupancy); % Vmin reset for enclosed office 2
            Vmin_vav1_ahu2=Vmin_RESET_z3(3,OccupancySchedule(OccTimestep,3),STD,Dense_Occupancy); % Vmin reset for enclosed office 5
            Vmin_vav2_ahu2=Vmin_RESET_z4(4,OccupancySchedule(OccTimestep,4),STD,Dense_Occupancy);   % Vmin reset for open office
        end
        % The extra control signal for MPC case (YC 2023/01/12)
        V_ahu1_sp=NaN;
        V_ahu2_sp=NaN;
        V_slSP_sp=NaN;
        % convert °F to °C
        Tz_cspt = (Tz_cspt-32)/1.8;
        Tz_hspt = (Tz_hspt-32)/1.8;
    case 1  % MPC control (YC 2022/09/12)
        modulate_PID=0;
        % insert a default SuperCtrlSig doc before the first GEB computation
        if timestep==(timestep_GEB_start(1)-GEB_step)
            SCS_default=struct('DocType','SuperCtrlSig_GEB','Timestep',0,'Time',0,...
                'FailFlag',0,'TConWatSupSet',0,'TChiWatSupSet',4.44,...
                'TSupAirSet',12.8,'TZonCooSet',25.56,'mFloSecPumSet',0,'mFloSupAirSet',0,'supFanOn',0,'mode',1,'OptiFlag',0,'predicted_power',0);
            insert(conn,CollName,SCS_default);
            MPC_KalFil_default=struct('DocType','MPC_KalFil_status','Timestep',0,'Time',0,...
                'Tz_kf',24,'Tw_kf',20,'To_kf',26);
            insert(conn,CollName,MPC_KalFil_default);
            
            % the MPC debug data (YC 2023/03/13)
            MPC_debugdata_default=struct('DocType','MPC_debugdata','Timestep',0,'Time',0,...
                'mode',0,'q_hvac_ch',0,'b_chc_ch',0,'b_chd_ch',0,'b_isd_ch',0,'q_chd_ch',0,'q_isd_ch',0,'Tz_pred_ch',0,'soc_pred_ch',0,'P_pred_ch',0);
            insert(conn,CollName,MPC_debugdata_default);
        end
        % start GEB computation
        if any(timestep==timestep_GEB_start)
            curtime=startTime+timestep*60;
            % save 'CurTime.mat' timestep curtime
            xlswrite('Time.xlsx',[timestep,curtime])
            % update the MPC simulation time (YC 2023/01/12)
%             poolobj = gcp('nocreate');
%             delete(poolobj);
%             open_system('GEB');
%             set_param(bdroot,'StartTime',string(curtime),'StopTime',string(curtime+15*60));
%             save_system(strcat(pwd,'\CTRL\GEB'));
%             close_system('GEB');
            % update the prices structure based on the location (YC 2023/02/15)
            if timestep==timestep_GEB_start(1)
                if Location_Num==1
                    TOU_price=[0.00746, 0.00746, 0.00746, 0.00746,...
                        0.00746, 0.00746, 0.00746, 0.00746,...
                        0.00746, 0.00746, 0.00746, 0.00746,...
                        0.00746, 0.01692, 0.01692, 0.01692,...
                        0.01692, 0.01692, 0.00746, 0.00746,...
                        0.00746, 0.00746, 0.00746, 0.00746];
                elseif Location_Num==2
                    TOU_price=[0.0298, 0.0298, 0.0298, 0.0298,...
                        0.0298, 0.0298, 0.0298, 0.0409,...
                        0.0409, 0.0409, 0.113, 0.113,...
                        0.113, 0.113, 0.113, 0.113,...
                        0.0409, 0.0409, 0.0409, 0.0298,...
                        0.0298, 0.0298, 0.0298, 0.0298];
                elseif Location_Num==3
                    TOU_price=[0.2700, 0.2700, 0.2700, 0.2700,...
                        0.2700, 0.2700, 0.2700, 0.2700,...
                        0.2700, 0.2700, 0.2700, 0.6948,...
                        0.6948, 0.6948, 0.6948, 0.6948,...
                        0.6948, 0.6948, 0.6948, 0.2700,...
                        0.2700, 0.2700, 0.2700, 0.2700];
                elseif Location_Num==4
                    TOU_price=[0.0256, 0.0256, 0.0256, 0.0256,...
                        0.0256, 0.0256, 0.0256, 0.0256,...
                        0.0256, 0.0256, 0.0256, 0.0256,...
                        0.0256, 0.0713, 0.0713, 0.0713,...
                        0.0713, 0.0713, 0.0713, 0.0256,...
                        0.0256, 0.0256, 0.0256, 0.0256];
                end
                load_system('GEB');
                set_param('GEB/hmpc','price_tou',['[',num2str(TOU_price),']']);
                set_param('GEB/kalmanFilter','X0','[24, 20, 26]');
                save_system('GEB');
                close_system('GEB');
            end
            
            % update the initial status of the Kalman Filter (YC 2023/02/07) 
            if timestep>timestep_GEB_start(1)
                MPC_KalFil_status_query=find(conn,CollName,'Query',['{"Timestep":',...
                    num2str(timestep-GEB_step),',"DocType":"MPC_KalFil_status"}']);
                if isempty(MPC_KalFil_status_query)
                    MPC_KalFil_status_query=find(conn,CollName,'Query',['{"Timestep":',...
                        num2str(timestep-2*GEB_step),',"DocType":"MPC_KalFil_status"}']);
                    MPC_KalFil_status_query.Timestep=MPC_KalFil_status_query.Timestep+GEB_step;
                    MPC_KalFil_status_query.Time=MPC_KalFil_status_query.Time+GEB_step*60;
                    MPC_KalFil_status_query=rmfield(MPC_KalFil_status_query,'x_id'); % Remove old id field
                    insert(conn,CollName,MPC_KalFil_status_query); % insert
                end
                Tz_kf=MPC_KalFil_status_query.Tz_kf;
                Tw_kf=MPC_KalFil_status_query.Tw_kf;
                To_kf=MPC_KalFil_status_query.To_kf;
                
                load_system('GEB');
                set_param('GEB/kalmanFilter','X0',['[' num2str(Tz_kf) ', ' num2str(Tw_kf) ', ' num2str(To_kf) ']']);
                save_system('GEB');
                close_system('GEB');
            end
            GEB_module = Simulink.SimulationInput('GEB');
            if isempty(GEB_background)
                GEB_background=parsim(GEB_module,'RunInBackground','on');
            else
                cancel(GEB_background);
                GEB_background=parsim(GEB_module,'RunInBackground','on');               
            end
            % pause(20)  % simulate the time using to run the interval timestep between two MPC reading time, which allows MPC to run to finish, should be delete in the formal test
        end
        % update CtrlSig according to SuperCtrlSig 
        % Get SuperCtrlSig from DB
        if any(timestep==timestep_GEB_read)
            CtrlSig_GEB=zeros(1,8);
            SCS_query=find(conn,CollName,'Query',['{"Timestep":',...
                num2str(timestep-GEB_step),',"DocType":"SuperCtrlSig_GEB"}']);
            % if GEB fail to finish in time, use the old one
            if isempty(SCS_query)
                SCS_query=find(conn,CollName,'Query',['{"Timestep":',...
                    num2str(timestep-2*GEB_step),',"DocType":"SuperCtrlSig_GEB"}']);
                SCS_query.Timestep=SCS_query.Timestep+GEB_step;
                SCS_query.Time=SCS_query.Time+GEB_step*60;
                SCS_query.FailFlag=1;   % Computation failed
                SCS_query=rmfield(SCS_query,'x_id'); % Remove old id field
                insert(conn,CollName,SCS_query); % insert
                SCS_query=find(conn,CollName,'Query',['{"Timestep":',...
                    num2str(timestep-GEB_step),',"DocType":"SuperCtrlSig_GEB"}']);
            end
        end
        if timestep>=timestep_GEB_read(1)
            SCS_field=fieldnames(SCS_query);
            % update CtrlSig
            for i=1:8
                CtrlSig_GEB(i)=SCS_query.(char(SCS_field(i+5)));
                % CtrlSig_GEB(1)=TConWatSupSet
                % CtrlSig_GEB(2)=TChiWatSupSet
                % CtrlSig_GEB(3)=TSupAirSet
                % CtrlSig_GEB(4)=TZonCooSet
                % CtrlSig_GEB(5)=mFloSecPumSet
                % CtrlSig_GEB(6)=mFloSupAirSet
                % CtrlSig_GEB(7)=supFanOn
            end
            if CtrlSig_GEB(8)==1 
                sys_status=0;
            elseif CtrlSig_GEB(8)==4 || CtrlSig_GEB(8)==2
                sys_status=1;
            end
            T_chwst=CtrlSig_GEB(2);
            DP_slSP=NaN;
            P_sp_ahu1=NaN;
            P_sp_ahu2=NaN;
            T_SA_ahu1=CtrlSig_GEB(3);
            T_SA_ahu2=CtrlSig_GEB(3);
            if CtrlSig_GEB(8)==2 || CtrlSig_GEB(8)==3
                TS_mode=1;
            elseif CtrlSig_GEB(8)==5
                TS_mode=2;
            else
                TS_mode=0;
            end
            if sys_status==1
                load('OccSche.mat')
                Vmin_vav1_ahu1=Vmin_RESET_z1(1,OccupancySchedule(OccTimestep,1),STD,Dense_Occupancy);   % Vmin reset for conference room
                Vmin_vav2_ahu1=Vmin_RESET_z2(2,OccupancySchedule(OccTimestep,2),STD,Dense_Occupancy); % Vmin reset for enclosed office 2
                Vmin_vav1_ahu2=Vmin_RESET_z3(3,OccupancySchedule(OccTimestep,3),STD,Dense_Occupancy); % Vmin reset for enclosed office 5
                Vmin_vav2_ahu2=Vmin_RESET_z4(4,OccupancySchedule(OccTimestep,4),STD,Dense_Occupancy);   % Vmin reset for open office
            else
                Vmin_vav1_ahu1=0;
                Vmin_vav2_ahu1=0;
                Vmin_vav1_ahu2=0;
                Vmin_vav2_ahu2=0;
            end
            m_vav1_ahu1_sp=NaN;
            m_vav2_ahu1_sp=NaN;
            m_vav1_ahu2_sp=NaN;
            m_vav2_ahu2_sp=NaN;
            
            m_slSP=CtrlSig_GEB(5);
            m_ahu=CtrlSig_GEB(6);
            Airkgs2cfm=2118.88/1.25;
            Waterkgs2gpm=60*264.17/1030;
            % distribute the extra air flow rate (YC 2023/02/15)
            m_ahu_cfm=m_ahu*Airkgs2cfm;
            m_ahu_cfm_ext=m_ahu_cfm-1060;
            if m_ahu_cfm_ext<0
                m_ahu_cfm_ext=0;
            end
                       
            Meas_MPC=find(conn,CollName,'Query','{"DocType":"Measurements_MPC"}');
            Meas_MPC=Meas_MPC((end-14):end);
            % V_ahu1_sp=(mean([Meas_MPC.vav3_d_sp])+mean([Meas_MPC.vav4_d_sp]))/(mean([Meas_MPC.vav1_d_sp])+mean([Meas_MPC.vav2_d_sp])+mean([Meas_MPC.vav3_d_sp])+mean([Meas_MPC.vav4_d_sp]))*m_ahu*Airkgs2cfm;
            % V_ahu2_sp=(mean([Meas_MPC.vav1_d_sp])+mean([Meas_MPC.vav2_d_sp]))/(mean([Meas_MPC.vav1_d_sp])+mean([Meas_MPC.vav2_d_sp])+mean([Meas_MPC.vav3_d_sp])+mean([Meas_MPC.vav4_d_sp]))*m_ahu*Airkgs2cfm;
            % the extra air flow demand of the AHUs (YC 2023/02/15)
            vav3_ext_d_m=mean([Meas_MPC.vav3_d_sp])-460;
            if vav3_ext_d_m<0
                vav3_ext_d_m=0;
            end
            vav4_ext_d_m=mean([Meas_MPC.vav4_d_sp])-200;
            if vav4_ext_d_m<0
                vav4_ext_d_m=0;
            end
            vav1_ext_d_m=mean([Meas_MPC.vav1_d_sp])-200;
            if vav1_ext_d_m<0
                vav1_ext_d_m=0;
            end
            vav2_ext_d_m=mean([Meas_MPC.vav2_d_sp])-200;
            if vav2_ext_d_m<0
                vav2_ext_d_m=0;
            end
            
            if sys_status==1
                % if (vav3_ext_d_m+vav4_ext_d_m+vav1_ext_d_m+vav2_ext_d_m)>0
                %   V_ahu1_sp=460+200+((vav3_ext_d_m+vav4_ext_d_m)/(vav1_ext_d_m+vav2_ext_d_m+vav3_ext_d_m+vav4_ext_d_m))*m_ahu_cfm_ext;
                %   V_ahu2_sp=200+200+((vav1_ext_d_m+vav2_ext_d_m)/(vav1_ext_d_m+vav2_ext_d_m+vav3_ext_d_m+vav4_ext_d_m))*m_ahu_cfm_ext;
                % else
                %   V_ahu1_sp=460+200+((460+200)/(460+200+200+200))*m_ahu_cfm_ext;
                %   V_ahu2_sp=200+200+((200+200)/(460+200+200+200))*m_ahu_cfm_ext;
                % end
                
                % divide the air flow based on the zone area ratio (YC 2023/03/07)
                % V_ahu1_sp=m_ahu_cfm*(0.144+0.105);
                % V_ahu2_sp=m_ahu_cfm*(0.646+0.105);
                % divide the air flow based on the zone load (YC 2023/03/31)
                V_ahu1_sp=m_ahu_cfm*(0.31+0.18);
                V_ahu2_sp=m_ahu_cfm*(0.18+0.33);
            else
                V_ahu1_sp=0;
                V_ahu2_sp=0;
            end
            
            V_slSP_sp=m_slSP*Waterkgs2gpm;
            if CtrlSig_GEB(4)==0
                if (timestep>(OccupiedPeriod(1)-40)) && (timestep<=(OccupiedPeriod(2)+80))
                    Tz_cspt=78;
                else
                    Tz_cspt=90;
                end
            else
                Tz_cspt=(CtrlSig_GEB(4))*1.8+32;
            end
        else
            V_ahu1_sp=0;
            V_ahu2_sp=0;
            V_slSP_sp=0;
        end
        % convert °F to °C
        Tz_cspt = (Tz_cspt-32)/1.8;
        Tz_hspt = (Tz_hspt-32)/1.8;
        
        if ismember(timestep,[361:1200]) && (CtrlSig_GEB(8)~=4 && CtrlSig_GEB(8)~=2) && TS_mode~=1
            sys_status=1;
            T_chwst=4.44;
            T_SA_ahu1=12.8;
            T_SA_ahu2=12.8;
            V_ahu1_sp=460+200;
            V_ahu2_sp=200+200;
            V_slSP_sp=14.7730;
        end
end

%% Outputs
CtrlSig(1,1:20) = [1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0];
if Control_method==1
    CtrlSig(1,1:20) = [1,1,1,0,0,0,1,1,1,1,1,1,1,0,0,0,0,1,1,1];
end
CtrlSig(2,1:20) = [sys_status,modulate_PID,T_chwst,DP_slSP,P_sp_ahu1,P_sp_ahu2,T_SA_ahu1,T_SA_ahu2,TS_mode,...
    Vmin_vav1_ahu1,Vmin_vav2_ahu1,Vmin_vav1_ahu2,Vmin_vav2_ahu2,...
    m_vav1_ahu1_sp,m_vav2_ahu1_sp,m_vav1_ahu2_sp,m_vav2_ahu2_sp,...
    V_ahu1_sp,V_ahu2_sp,V_slSP_sp];

%% save control signals to MongoDB
CtrlSigDoc.DocType = 'SupvCtrlSig';
CtrlSigDoc.Timestep = timestep;
CtrlSigDoc.Time = startTime+timestep*60;
CtrlSigDoc.sys_status = CtrlSig(:,1);
CtrlSigDoc.T_chwst = CtrlSig(:,3);
CtrlSigDoc.DP_slSP = CtrlSig(:,4);
CtrlSigDoc.P_sp_ahu1 = CtrlSig(:,5);
CtrlSigDoc.P_sp_ahu2 = CtrlSig(:,6);
CtrlSigDoc.T_SA_ahu1 = CtrlSig(:,7);
CtrlSigDoc.T_SA_ahu2 = CtrlSig(:,8);
CtrlSigDoc.TS_mode = CtrlSig(:,9);
CtrlSigDoc.Vmin_vav1_ahu1 = CtrlSig(:,10);
CtrlSigDoc.Vmin_vav2_ahu1 = CtrlSig(:,11);
CtrlSigDoc.Vmin_vav1_ahu2 = CtrlSig(:,12);
CtrlSigDoc.Vmin_vav2_ahu2 = CtrlSig(:,13);
CtrlSigDoc.m_vav1_ahu1_sp = CtrlSig(:,14);
CtrlSigDoc.m_vav2_ahu1_sp = CtrlSig(:,15);
CtrlSigDoc.m_vav1_ahu2_sp = CtrlSig(:,16);
CtrlSigDoc.m_vav2_ahu2_sp = CtrlSig(:,17);
CtrlSigDoc.Tz_cspt = [1;Tz_cspt];
CtrlSigDoc.Tz_hspt = [1;Tz_hspt];
CtrlSigDoc.V_ahu1_sp = CtrlSig(:,18);
CtrlSigDoc.V_ahu2_sp = CtrlSig(:,19);
CtrlSigDoc.V_slSP_sp = CtrlSig(:,20);
insert(conn,CollName,CtrlSigDoc);
end

