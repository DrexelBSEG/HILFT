function CtrlSig = Control_Model(startTime,timestep,Season_type,GEB_case,Control_method,TES,Meas,STD,Dense_Occupancy,conn,CollName)
%% inputs
% startTime:start time in seconds of the tested DOY
% timestep: current timestep
% Season_type: used to determine whether daylight saving (1-typical winter;2-typical shoulder;3-extreme summer;4-typical summer)
% TES: whether to test ice tank (0-no, 1-yes)
% GEB_case: GEB scenario to be tested (0-none,1-eff,2-shed,3-shift,4-modulate)
% GEB_control: GEB control method (0-rule based, 1-MPC)
% STD: building code standard (1-STD2004;2-STD2019)
% Dense_Occupancy: 0-typical occupancy; 1-dense occupancy
% conn: database connection cursor
% CollName: database collection name
% Meas:
%     m_sup = Meas(1) :       discharge air mass flow rate [kg/s]
%     T_sup = Meas(2) :       discharge air temperature [°C]
%     w_sup = Meas(3) :       discharge air humidity ratio [kg/kg]
%     T_z = Meas(4) :         (emulated chamber) zone air temperature [°C]
%     w_z = Meas(5) :         (emulated chamber) zone humidity ratio [kg/kg]
%     T_out_emulated = Meas(6) :    emulated side outdoor air temperature for ASHP or outdoor water temperature for WSHP [°C]
%     Power_HVAC_electric = Meas(7);     Total electric power of HVAC system including primary/secondary system [kW]
%% outputs
% CtrlSig(1,1:2)
%     Take the CtrlSig(2,i) setpoint only when CtrlSig(1,i)==1
% CtrlSig(2,1:2) = [sys_status,modulate_PID]
%     sys_status:       system status (0-off,1-on)
%     modulate_PID:     Activate modulate PID (0-off,1-on)
%% Main program
%% read measurements
% zone-level measurements
m_sup = Meas(1);
T_sup = Meas(2);
w_sup = Meas(3);
T_z = Meas(4);
w_z = Meas(5);
% emulated outdoor air/water temperature
T_out_emulated = Meas(6);
%% persistent TOU structure
persistent PeakPeriod CollNmae_sparate Location Location_Num ShiftSche
persistent timestep_GEB_start timestep_GEB_read GEB_step GEB_background CtrlSig_GEB SCS_query SCS_last_query
%% ASHP MPC setup 
if Control_method==1 && isempty(GEB_step)
    par_dir = fileparts(strcat(pwd,'\callSim.m'));
    addpath(strcat(par_dir,'\CTRL\MPC'));
    addpath(fullfile(par_dir, '\CTRL\MPC\casadi-windows-v3.5.5')); % add casadi to path
    addpath(fullfile(par_dir, '\CTRL\MPC\load-shifting')); 
    addpath(fullfile(par_dir, '\CTRL\MPC\load-shifting\cooling-only')); 
    addpath('C:\gurobi1000\win64\matlab') % add gurobi matlab api to matlab
    timestep_GEB_start = (15:15:90*15);
    timestep_GEB_read = ((15+15):15:91*15);
    parpool('local',2);
    GEB_module = Simulink.SimulationInput('GEB_ASHP');
    GEB_step=15;  % number of timesteps between two GEB calls
end
%% determine whether daylight saving
% Occupancy period is from 6:00 to 22:00 (standard time)
OccupiedPeriod=[6*60 22*60];
if Season_type==1 % typical winter, no daylight saving. clock time=standard time
    OccupiedPeriod=OccupiedPeriod;
    DaylightSaving=0;
%     OccTimestep=timestep;
else % for other test date, it is winin daylight saving period, clok time=standard time - 60min
    OccupiedPeriod=OccupiedPeriod-60;
    DaylightSaving=1;
%     OccTimestep=timestep+60;   % OccTimesetp is used to locate the occupant schedule.
%     if OccTimestep>1440
%         OccTimestep=OccTimestep-1440;
%     end
end
%% determine system operation
% system operation hour is the same as occupied hour
if (timestep>(OccupiedPeriod(1))) && (timestep<=(OccupiedPeriod(2)))
    sys_status = 1;
else
    if Control_method==1
        sys_status = 1;
    else
        sys_status = 0;
    end
end
% determine whether occupied 
if (timestep>OccupiedPeriod(1)) && (timestep<=OccupiedPeriod(2))
    Occupied = 1;
else
    Occupied = 0;
end
%% set to default setpoint 
[Tz_hspt,Tz_cspt]=DefaultSettingHP(sys_status,Season_type,Occupied);
%% initialized the peak period for four location and three seasons
if isempty(PeakPeriod)
    PeakPeriod=cell(4,4);
    PeakPeriod{1,1}=[99 99];  % Atlanta typical winter
    PeakPeriod{1,2}=[99 99];  % Atlanta typical shoulder
    PeakPeriod{1,3}=[14 19];  % Atlanta extreme summer
    PeakPeriod{1,4}=[14 19];  % Atlanta typical summer
    PeakPeriod{2,1}=[17 20];
    PeakPeriod{2,2}=[99 99];
    PeakPeriod{2,3}=[11 17];
    PeakPeriod{2,4}=[11 17];
    PeakPeriod{3,1}=[12 20];
    PeakPeriod{3,2}=[12 20];
    PeakPeriod{3,3}=[12 20];
    PeakPeriod{3,4}=[12 20];
    PeakPeriod{4,1}=[6 10 17 21];
    PeakPeriod{4,2}=[6 10 17 21];
    PeakPeriod{4,3}=[14 20];
    PeakPeriod{4,4}=[14 20];
    
    ShiftSche=cell(4,4);
    ShiftSche{1,1}=[0 0]; % Atlanta typical winter
    ShiftSche{1,2}=[0 0]; % Atlanta typical shoulder
    ShiftSche{1,3}=[2 0.5]; % Atlanta extreme summer
    ShiftSche{1,4}=[2 0.5]; % Atlanta typical summer (the dT of precooling/heating, the duration)
    ShiftSche{2,1}=[1 0.5];
    ShiftSche{2,2}=[0 0];
    ShiftSche{2,3}=[3 0.5];
    ShiftSche{2,4}=[1 0.5];
    ShiftSche{3,1}=[1 0.5];
    ShiftSche{3,2}=[1 4.5];
    ShiftSche{3,3}=[1 3];
    ShiftSche{3,4}=[1 5];
    ShiftSche{4,1}=[1 0.5];
    ShiftSche{4,2}=[1 0.5];
    ShiftSche{4,3}=[2 1.5];
    ShiftSche{4,4}=[1 1];

    CollNmae_sparate=strsplit(CollName,'_');
    Location=CollNmae_sparate{1};
    if strcmp(Location,'Atlanta')
        Location_Num=1;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_a\cooling'))); % add cooling and subfolders to path
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_a')));
            addpath(fullfile(par_dir, 'CTRL\MPC\system-identification_a\fan'))
        end
    elseif strcmp(Location,'Buffalo')
        Location_Num=2;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_b\cooling'))); % add cooling and subfolders to path
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_b')));
            addpath(fullfile(par_dir, 'CTRL\MPC\system-identification_b\fan'))
        end
    elseif strcmp(Location,'NewYork')
        Location_Num=3;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_ny\cooling'))); % add cooling and subfolders to path
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_ny')));
            addpath(fullfile(par_dir, 'CTRL\MPC\system-identification_ny\fan'))
        end
    elseif strcmp(Location,'Tucson')
        Location_Num=4;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_t\cooling'))); % add cooling and subfolders to path
            addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_t')));
            addpath(fullfile(par_dir, 'CTRL\MPC\system-identification_t\fan'))
        end
    end
end
%% determine setpoints
% initialized vav mass flow rate setpoints. will only be used when
% GEB_control==1 (MPC mode)
m_sp = 0;
if Season_type==1   % winter case, reset the heating setpoint
    switch Control_method
        case 0  % Rule-based control
            % determine zone-level setpoints
            %!!!!!!!!!! need to be modified after utility programs are decided
            modulate_PID = 0;
            if (GEB_case>0) % for all GEB cases
                if sys_status==1
                    % GEB_case==1,2,3, use different zone temperature setpoint
                    if (GEB_case==1)
                        Tz_hspt = Tz_hspt;
                    elseif (GEB_case==2)
                        if Location_Num==4 
                            shed_start_1=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end_1=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            shed_start_2=(PeakPeriod{Location_Num,(Season_type)}(3)-DaylightSaving)*60;
                            shed_end_2=(PeakPeriod{Location_Num,(Season_type)}(4)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start_1 && timestep<=shed_end_1) ||...
                                        (timestep>shed_start_2 && timestep<=shed_end_2)
                                    Tz_hspt = 66;
                                    Tz_cspt = 80;
                                end
                            end
                        else
                            shed_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start && timestep<=shed_end)
                                    Tz_hspt = 66;
                                    Tz_cspt = 80;
                                end
                            end
                        end
                    elseif (GEB_case==3)
                        PL=ShiftSche{Location_Num,Season_type}(2);
                        PTSC=ShiftSche{Location_Num,Season_type}(1);
                        if Location_Num==4 
                            preheat_start=(PeakPeriod{Location_Num,(Season_type)}(3)-DaylightSaving-PL)*60;  % for Tucson TypWin case, only shift in second peak period
                            shed_start_1=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end_1=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            shed_start_2=(PeakPeriod{Location_Num,(Season_type)}(3)-DaylightSaving)*60;
                            shed_end_2=(PeakPeriod{Location_Num,(Season_type)}(4)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start_1 && timestep<=shed_end_1) ||...
                                        (timestep>shed_start_2 && timestep<=shed_end_2)
                                    Tz_hspt = 66;
                                elseif (timestep>preheat_start && timestep<=shed_start_2)
                                    Tz_hspt = Tz_hspt+PTSC;
                                end
                            end
                        else
                            preheat_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving-PL)*60;
                            shed_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start && timestep<=shed_end)
                                    Tz_hspt = 66;
                                elseif (timestep>preheat_start && timestep<=shed_start)
                                    Tz_hspt = Tz_hspt+PTSC;
                                end
                            end
                        end
                    elseif (GEB_case==4)
                        Tz_hspt = Tz_hspt;
                        modulate_PID = 1;   % activate modulate PID
                    end
                else
                    [Tz_hspt,Tz_cspt]=DefaultSettingHP(sys_status,Season_type,Occupied);
                end
            else
                [Tz_hspt,Tz_cspt]=DefaultSettingHP(sys_status,Season_type,Occupied);
            end
            % convert °F to °C
            Tz_cspt = (Tz_cspt-32)/1.8;
            Tz_hspt = (Tz_hspt-32)/1.8;
        case 1  
            
    end
            
else    % for other case, reset cooling setpoint
    switch Control_method
        case 0  % Rule-based control
            % determine zone-level setpoints
            %!!!!!!!!!! need to be modified after utility programs are decided
            modulate_PID = 0;
            if (GEB_case>0) % for all GEB cases
                if sys_status==1
                    % GEB_case==1,2,3, use different zone temperature setpoint
                    if (GEB_case==1)
                        Tz_cspt = Tz_cspt;
                    elseif (GEB_case==2)
                        if Location_Num==4 && Season_type==2
                            shed_start_1=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end_1=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            shed_start_2=(PeakPeriod{Location_Num,(Season_type)}(3)-DaylightSaving)*60;
                            shed_end_2=(PeakPeriod{Location_Num,(Season_type)}(4)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start_1 && timestep<=shed_end_1) ||...
                                        (timestep>shed_start_2 && timestep<=shed_end_2)
                                    Tz_hspt = 66;
                                    Tz_cspt = 80;
                                end
                            end
                        else
                            shed_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start && timestep<=shed_end)
                                    Tz_hspt = 66;
                                    Tz_cspt = 80;
                                end
                            end
                        end
                    elseif (GEB_case==3)
                        PL=ShiftSche{Location_Num,Season_type}(2);
                        PTSC=ShiftSche{Location_Num,Season_type}(1);
                        if Location_Num==4 && Season_type==2
                            precool_start=(PeakPeriod{Location_Num,(Season_type)}(3)-DaylightSaving-PL)*60;  % for Tucson TypSholr case, only shift in second peak period
                            shed_start_1=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end_1=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            shed_start_2=(PeakPeriod{Location_Num,(Season_type)}(3)-DaylightSaving)*60;
                            shed_end_2=(PeakPeriod{Location_Num,(Season_type)}(4)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start_1 && timestep<=shed_end_1) ||...
                                        (timestep>shed_start_2 && timestep<=shed_end_2)
                                    Tz_cspt = 80;
                                elseif (timestep>precool_start && timestep<=shed_start_2)
                                    Tz_cspt = Tz_cspt-PTSC;
                                end
                            end
                        else
                            precool_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving-PL)*60;
                            shed_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
                            shed_end=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
                            if (sys_status>0)
                                if (timestep>shed_start && timestep<=shed_end)
                                    Tz_cspt = 80;
                                elseif (timestep>precool_start && timestep<=shed_start)
                                    Tz_cspt = Tz_cspt-PTSC;
                                end
                            end
                        end
                    elseif (GEB_case==4)
                        Tz_cspt = Tz_cspt;
                        modulate_PID = 1;   % activate modulate PID
                    end
                else
                    [Tz_hspt,Tz_cspt]=DefaultSettingHP(sys_status,Season_type,Occupied);
                end
            else
                [Tz_hspt,Tz_cspt]=DefaultSettingHP(sys_status,Season_type,Occupied);
            end
            % convert °F to °C
            Tz_cspt = (Tz_cspt-32)/1.8;
            Tz_hspt = (Tz_hspt-32)/1.8;
        case 1  % MPC control (YC 2023/03/07)
            modulate_PID=0;
            % insert a default SuperCtrlSig doc before the first GEB computation
            if timestep==(timestep_GEB_start(1)-GEB_step)
                SCS_default=struct('DocType','SuperCtrlSig_GEB','Timestep',0,'Time',0,...
                    'FailFlag',0,'TZonCooSet',32.22,'TZonHeaSet',12.78,'Mode',0,'OptiFlag',1);
                insert(conn,CollName,SCS_default);
                MPC_KalFil_default=struct('DocType','MPC_KalFil_status','Timestep',0,'Time',0,...
                    'Tz_kf',24,'Tw_kf',20,'To_kf',26);
                insert(conn,CollName,MPC_KalFil_default);
                MPC_DebugData_default=struct('DocType','MPC_DebugData','Timestep',0,'Time',0,...
                    'p_pred_ch',0,'q_pred_ch',0,'Tz_pred_ch',0,'price_ch',0);
                insert(conn,CollName,MPC_DebugData_default);
            end
            % start GEB computation
            if any(timestep==timestep_GEB_start)
                curtime=startTime+timestep*60;
                % save 'CurTime.mat' timestep curtime
                xlswrite('Time.xlsx',[timestep,curtime])
                % update the prices structure based on the location
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
                    load_system('GEB_ASHP');
                    set_param('GEB_ASHP/mpc','price_tou',['[',num2str(TOU_price),']']);
                    % update the X0 for RC model (YC 2024/01/18)
                    SimData_0=find(conn,CollName,'Query',['{"Timestep":',...
                        num2str(timestep-1),',"DocType":"SimData"}']);
                    Tz_sim_0=SimData_0.T_z;
                    Twe_0=32.28+10;  % based on RC model calibration result and the initial offset
                    Twi_0=26.53+1;
                    set_param('GEB_ASHP/kalmanFilter','X0',['[' num2str(Tz_sim_0) ', ' num2str(Twe_0) ', ' num2str(Twi_0) ']']);
                    save_system('GEB_ASHP');
                    close_system('GEB_ASHP');
                end
                % update the initial status of the Kalman Filter (YC 2023/02/07)
                if timestep>timestep_GEB_start(1)
                    MPC_KalFil_status_query=find(conn,CollName,'Query',['{"Timestep":',...
                        num2str(timestep-GEB_step),',"DocType":"MPC_KalFil_status"}']);
                    % update the Tz initial status using Tz_sim (YC 2024/01/19)
                    SimData_0=find(conn,CollName,'Query',['{"Timestep":',...
                        num2str(timestep-1),',"DocType":"SimData"}']);
                    Tz_sim_0=SimData_0.T_z;
                    
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
                    
                    load_system('GEB_ASHP');
                    set_param('GEB_ASHP/kalmanFilter','X0',['[' num2str(Tz_sim_0) ', ' num2str(Tw_kf) ', ' num2str(To_kf) ']']);
                    save_system('GEB_ASHP');
                    close_system('GEB_ASHP');
                end
                GEB_module = Simulink.SimulationInput('GEB_ASHP');
                if isempty(GEB_background)
                    GEB_background=parsim(GEB_module,'RunInBackground','on');
                else
                    cancel(GEB_background);
                    GEB_background=parsim(GEB_module,'RunInBackground','on');
                end
            end
            
            % read the MPC control signal once MPC finish (YC 2024/01/08)
            if timestep>timestep_GEB_start(1)
                CtrlSig_GEB=zeros(1,2);
                SCS_query_all=find(conn,CollName,'Query',['{"DocType":"SuperCtrlSig_GEB"}']);
                SCS_query_newest=SCS_query_all(end);
                SCS_field=fieldnames(SCS_query_newest);
                % update CtrlSig
                for i=1:2
                    CtrlSig_GEB(i)=SCS_query_newest.(char(SCS_field(i+5)));
                end
                Tz_cspt=CtrlSig_GEB(1);
                Tz_hspt=CtrlSig_GEB(2);
            else
                Tz_cspt = (Tz_cspt-32)/1.8;
                Tz_hspt = (Tz_hspt-32)/1.8;
            end
            
             if any(timestep==timestep_GEB_read)
                CtrlSig_GEB=zeros(1,2);
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
            
            % adjust a Tz_cspt output from MPC so that the real system can
            % run in the specified mode (YC 2024/01/04)
            if timestep>=timestep_GEB_read(1)
                if SCS_query_newest.Mode==0
                    Tz_cspt = (90-32)/1.8;
                elseif SCS_query_newest.Mode==1
                    SimData_last=find(conn,CollName,'Query',['{"Timestep":',num2str(timestep-1),',"DocType":"SimData"}']);
                    Tz_last=SimData_last.T_z;
                    if Meas(1)<0.3  % determine system current mode based on m_sup
                        Tz_cspt=Tz_last-0.75/1.8;
                    elseif Meas(1)>=0.3 && Meas(1)<0.5
                        Tz_cspt=Tz_last-0.5/1.8;
                    elseif Meas(1)>=0.5
                        Tz_cspt=Tz_last-0.25/1.8;
                    end
                elseif SCS_query_newest.Mode==2
                    Tz_cspt = (70-32)/1.8;
                end
            end
            
            % add a rule to adjusted the Tz_cspt output from MPC if MPC
            % failed, no converged, or decide to off mode (YC 2023/12/21)
            shed_start=(PeakPeriod{Location_Num,(Season_type)}(1)-DaylightSaving)*60;
            shed_end=(PeakPeriod{Location_Num,(Season_type)}(2)-DaylightSaving)*60;
            if timestep>=timestep_GEB_read(2)
                if any(timestep==timestep_GEB_read)
                    SCS_last_query=find(conn,CollName,'Query',['{"Timestep":',...
                        num2str(timestep-2*GEB_step),',"DocType":"SuperCtrlSig_GEB"}']);
                end
                if (SCS_query.FailFlag==1 || SCS_query.OptiFlag==0) && (SCS_last_query.FailFlag==1 || SCS_last_query.OptiFlag==0)
                    if (GEB_case==2 || GEB_case==3) && (timestep>shed_start && timestep<=shed_end)
                        Tz_cspt = (80-32)/1.8;
                    else
                        if Occupied==1
                            Tz_cspt = (78-32)/1.8;
                        else
                            Tz_cspt = (90-32)/1.8;
                        end
                    end
                end
            end

    end
end

%% Outputs
CtrlSig(1,1:2) = [1,1];
if Control_method==1
    CtrlSig(1,1:2) = [1,1];
end
CtrlSig(2,1:2) = [sys_status,modulate_PID];

%% save control signals to MongoDB
    CtrlSigDoc.DocType = 'SupvCtrlSig';
    CtrlSigDoc.Timestep = timestep;
    CtrlSigDoc.Time = startTime+timestep*60;
    CtrlSigDoc.sys_status = CtrlSig(:,1);
    CtrlSigDoc.Tz_cspt = [1;Tz_cspt];
    CtrlSigDoc.Tz_hspt = [1;Tz_hspt];    
    insert(conn,CollName,CtrlSigDoc);  
end

