function [CtrlSig,MPC_DebugData_ouput] = Control_Model(startTime,timestep,Season_type,GEB_case,Control_method,TES,Meas,STD,Dense_Occupancy,conn,CollName,Meas_MPC)
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
% MPC_DebugData
%   MPC_DebugData(1)=status;
%   MPC_DebugData(2)=T2_opt;
%   MPC_DebugData(3)=y_opt;
%   MPC_DebugData(4)=q_opt;
%   MPC_DebugData(5)=p_opt;
%   MPC_DebugData(6)=price;
%   MPC_DebugData(7)=Tz_opt; % The zone temperature output from MPC
%   MPC_DebugData(8)=Tub_i; 
%   MPC_DebugData(9)=Tlb_i; 
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
persistent timestep_GEB_start timestep_GEB_read GEB_step GEB_background CtrlSig_GEB SCS_query 
persistent MPC_DebugData_query MPC_DebugData reg2
%% ASHP MPC setup 
if Control_method==1 && isempty(GEB_step)
    par_dir = fileparts(strcat(pwd,'\callSim.m'));
    addpath(strcat(par_dir,'\CTRL\MPC'));
    addpath(fullfile(par_dir, '\CTRL\MPC\casadi-windows-v3.5.5')); % add casadi to path
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
    sys_status = 0;
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
            addpath(strcat(par_dir,'\CTRL\MPC\Disturbances\Atlanta_2015')); 
        end
    elseif strcmp(Location,'Buffalo')
        Location_Num=2;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(strcat(par_dir,'\CTRL\MPC\Disturbances\Buffalo_2014')); 
        end
    elseif strcmp(Location,'NewYork')
        Location_Num=3;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(strcat(par_dir,'\CTRL\MPC\Disturbances\NewYork_2013')); 
        end
    elseif strcmp(Location,'Tucson')
        Location_Num=4;
        if Control_method==1
            par_dir = fileparts(strcat(pwd,'\callSim.m'));
            addpath(strcat(par_dir,'\CTRL\MPC\Disturbances\Tucson_2019')); 
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
                    'FailFlag',0,'TZonCooSet',32.22,'TZonHeaSet',12.78,'OptiFlag',1);
                insert(conn,CollName,SCS_default);
                x_opt_default=struct('DocType','x_opt','Timestep',0,'Time',0,...
                    'x_opt1',0,'x_opt2',0,'x_opt3',0,'x_opt4',0);
                insert(conn,CollName,x_opt_default);
                MPC_DebugData_default=struct('DocType','MPC_DebugData','Timestep',0,'Time',0,...
                    'status',0,'T2_opt',0,'y_opt',0,'q_opt',0,'p_opt',0,'price',0,'Tub_i',0,'Tlb_i',0,'Tz_opt',0);
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
                    load_system('HILFT_WSHP_MPC_2020a');
                    set_param('HILFT_WSHP_MPC_2020a/MPC','price_tou',['[',num2str(TOU_price),']']);
                    set_param('HILFT_WSHP_MPC_2020a/initial u_prev','Value','[0 0 0 0]');
                    save_system('HILFT_WSHP_MPC_2020a');
                    close_system('HILFT_WSHP_MPC_2020a');
                    % initial x_opt for debugging (YC 2024/01/02)
                    x_opt_rec=[];
                    save('x_opt_rec.mat','x_opt_rec')
                end
                % update the initial u_prev (YC 2023/11/09)
                if timestep>timestep_GEB_start(1)
                    x_opt_query=find(conn,CollName,'Query',['{"Timestep":',...
                        num2str(timestep-GEB_step),',"DocType":"x_opt"}']);
                    if isempty(x_opt_query)
                        x_opt_query=find(conn,CollName,'Query',['{"Timestep":',...
                            num2str(timestep-2*GEB_step),',"DocType":"x_opt"}']);
                        x_opt_query.Timestep=x_opt_query.Timestep+GEB_step;
                        x_opt_query.Time=x_opt_query.Time+GEB_step*60;
                        x_opt_query=rmfield(x_opt_query,'x_id'); % Remove old id field
                        insert(conn,CollName,x_opt_query); % insert
                    end
                    x_opt_prev=[x_opt_query.x_opt1,x_opt_query.x_opt2,x_opt_query.x_opt3,x_opt_query.x_opt4];
                    
                    load_system('HILFT_WSHP_MPC_2020a');
                    set_param('HILFT_WSHP_MPC_2020a/initial u_prev','Value',['[' num2str(x_opt_prev) ']']);
                    save_system('HILFT_WSHP_MPC_2020a');
                    close_system('HILFT_WSHP_MPC_2020a');
                end
                GEB_module = Simulink.SimulationInput('HILFT_WSHP_MPC_2020a');
                
                % save the x_opt for debugging (YC 2024/01/02)
                if any(timestep==timestep_GEB_read)
                    load('out_1.mat')
                    if exist('xout', 'var')
                        x_opt_temp{1,1}=timestep-15;
                        x_opt_temp{1,2}=xout{1}.Values.Data;
                        
                        load('x_opt_rec.mat')
                        x_opt_rec=[x_opt_rec;x_opt_temp];
                        save('x_opt_rec.mat','x_opt_rec')
                    end
                end
                
                if isempty(GEB_background)
                    GEB_background=parsim(GEB_module,'RunInBackground','on');
                else
                    cancel(GEB_background);
                    GEB_background=parsim(GEB_module,'RunInBackground','on');
                end
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
                
                % Get MPC debug data from DB (only for pretest) (YC 2023/12/01)
                MPC_DebugData=zeros(1,9);
                MPC_DebugData_query=find(conn,CollName,'Query',['{"Timestep":',...
                    num2str(timestep-GEB_step),',"DocType":"MPC_DebugData"}']);
                if isempty(MPC_DebugData_query)
                    MPC_DebugData=[999 999 999 999 999 999 999 999 999];
                    
                    MPC_DebugData_query=find(conn,CollName,'Query',['{"Timestep":',...
                    num2str(timestep-2*GEB_step),',"DocType":"MPC_DebugData"}']);
                    MPC_DebugData_query.Timestep=MPC_DebugData_query.Timestep+GEB_step;
                    MPC_DebugData_query.Time=MPC_DebugData_query.Time+GEB_step*60;
                    MPC_DebugData_query=rmfield(MPC_DebugData_query,'x_id'); % Remove old id field
                    insert(conn,CollName,MPC_DebugData_query); % insert
                else
                    MPC_DebugData(1)=MPC_DebugData_query.status;
                    MPC_DebugData(2)=MPC_DebugData_query.T2_opt;
                    MPC_DebugData(3)=MPC_DebugData_query.y_opt;
                    MPC_DebugData(4)=MPC_DebugData_query.q_opt;
                    MPC_DebugData(5)=MPC_DebugData_query.p_opt;
                    MPC_DebugData(6)=MPC_DebugData_query.price;
                    MPC_DebugData(7)=MPC_DebugData_query.Tz_opt;
                    MPC_DebugData(8)=MPC_DebugData_query.Tub_i;
                    MPC_DebugData(9)=MPC_DebugData_query.Tlb_i;
                end 
            end
            
            if timestep>=timestep_GEB_read(1)
                SCS_field=fieldnames(SCS_query);
                % update CtrlSig
                for i=1:2
                    CtrlSig_GEB(i)=SCS_query.(char(SCS_field(i+5)));
                end
                Tz_cspt=CtrlSig_GEB(1);
                Tz_hspt=CtrlSig_GEB(2);
                
                % adjust a Tz_cspt output from MPC so that the real system can
                % run in the specified speed (YC 2024/01/10)
                % if isempty(reg2)
                %     load('reg2.mat')
                % end
                % SimData_RFused=find(conn,CollName,'Query',['{"Timestep":',...
                %     num2str(timestep-1),',"DocType":"SimData"}']);
                % Tz_cspt=predict(reg2,[MPC_DebugData_query.y_opt,SimData_RFused.T_z]);
                
                % adjust the Tz_cspt using exhaustive optimization (YC 2024/02/20)
                inlet_water_temp=T_out_emulated;
                return_air_temp=T_z;
                return_air_hr=w_z;
                p_opt=MPC_DebugData_query.p_opt;
                acc_error=Meas_MPC(5);
                Tz_cspt=WSHP_Spt_Estimator(inlet_water_temp,return_air_temp,return_air_hr,p_opt,acc_error);
            else
                Tz_cspt = (Tz_cspt-32)/1.8;
                Tz_hspt = (Tz_hspt-32)/1.8;
            end
    end
end

%% Outputs
CtrlSig(1,1:2) = [1,1];
if Control_method==1
    CtrlSig(1,1:2) = [1,1];
end
CtrlSig(2,1:2) = [sys_status,modulate_PID];

% for the timestep before MPC run
if isempty(MPC_DebugData)
    MPC_DebugData=[999 999 999 999 999 999 999 999 999];
end
MPC_DebugData_ouput=MPC_DebugData;
%% save control signals to MongoDB
    CtrlSigDoc.DocType = 'SupvCtrlSig';
    CtrlSigDoc.Timestep = timestep;
    CtrlSigDoc.Time = startTime+timestep*60;
    CtrlSigDoc.sys_status = CtrlSig(:,1);
    CtrlSigDoc.Tz_cspt = [1;Tz_cspt];
    CtrlSigDoc.Tz_hspt = [1;Tz_hspt];    
    insert(conn,CollName,CtrlSigDoc);  
end

