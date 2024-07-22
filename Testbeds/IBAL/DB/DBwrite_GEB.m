function DBwrite_GEB(block)
%MSFUNTMPL_BASIC A Template for a Level-2 MATLAB S-Function
%   The MATLAB S-function is written as a MATLAB function with the
%   same name as the S-function. Replace 'msfuntmpl_basic' with the 
%   name of your S-function.

%   Copyright 2003-2018 The MathWorks, Inc.

%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%
setup(block);

%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C MEX counterpart: mdlInitializeSizes
%%
function setup(block)

% Register number of ports
block.NumInputPorts  = 1;
block.NumOutputPorts = 1;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;

% Override input port properties
block.InputPort(1).Dimensions        = 24;
block.InputPort(1).DatatypeID  = 0;  % double
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = true;

% Override output port properties
block.OutputPort(1).Dimensions       = 1;
block.OutputPort(1).DatatypeID  = 0; % double
block.OutputPort(1).Complexity  = 'Real';


% Register parameters
block.NumDialogPrms     = 0;

% Register sample times
%  [0 offset]            : Continuous sample time
%  [positive_num offset] : Discrete sample time
%
%  [-1, 0]               : Inherited sample time
%  [-2, 0]               : Variable sample time
block.SampleTimes = [0 0];

% Specify the block simStateCompliance. The allowed values are:
%    'UnknownSimState', < The default setting; warn and assume DefaultSimState
%    'DefaultSimState', < Same sim state as a built-in block
%    'HasNoSimState',   < No sim state
%    'CustomSimState',  < Has GetSimState and SetSimState methods
%    'DisallowSimState' < Error out when saving or restoring the model sim state
block.SimStateCompliance = 'DefaultSimState';

%% -----------------------------------------------------------------
%% The MATLAB S-function uses an internal registry for all
%% block methods. You should register all relevant methods
%% (optional and required) as illustrated below. You may choose
%% any suitable name for the methods and implement these methods
%% as local functions within the same file. See comments
%% provided for each function for more information.
%% -----------------------------------------------------------------

% block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
% block.RegBlockMethod('InitializeConditions', @InitializeConditions);
% block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
% block.RegBlockMethod('Update', @Update);
% block.RegBlockMethod('Derivatives', @Derivatives);
block.RegBlockMethod('Terminate', @Terminate); % Required

%end setup

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   Required         : No
%%   C MEX counterpart: mdlSetWorkWidths
%%
function DoPostPropSetup(block)
% block.NumDworks = 1;
%   
%   block.Dwork(1).Name            = 'x1';
%   block.Dwork(1).Dimensions      = 1;
%   block.Dwork(1).DatatypeID      = 0;      % double
%   block.Dwork(1).Complexity      = 'Real'; % real
%   block.Dwork(1).UsedAsDiscState = true;


%%
%% InitializeConditions:
%%   Functionality    : Called at the start of simulation and if it is 
%%                      present in an enabled subsystem configured to reset 
%%                      states, it will be called when the enabled subsystem
%%                      restarts execution to reset the states.
%%   Required         : No
%%   C MEX counterpart: mdlInitializeConditions
%%
function InitializeConditions(block)

%end InitializeConditions


%%
%% Start:
%%   Functionality    : Called once at start of model execution. If you
%%                      have states that should be initialized once, this 
%%                      is the place to do it.
%%   Required         : No
%%   C MEX counterpart: mdlStart
%%
function Start(block)
block.Dwork(1).Data = 0;

%end Start

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C MEX counterpart: mdlOutputs
%%
function Outputs(block)
persistent conn CollName SuperCtrlSig_GEB SuperCtrlSigField stop_time MPC_KalFil_status MPC_KalFil_statusField MPC_debugdata MPC_debugdata_Field
%% initiate DB connection
if isempty(CollName)
% database location
DBName=load('DBLoc.mat').DBName;
CollName=load('DBLoc.mat').CollName;
% connect to the database
conn = mongo('localhost',27017,DBName);
% field name
SuperCtrlSig_GEB=struct('DocType','SuperCtrlSig_GEB','Timestep',0,'Time',0,...
    'FailFlag',0,'TConWatSupSet',0,'TChiWatSupSet',0,...
    'TSupAirSet',0,'TZonCooSet',0,'mFloSecPumSet',0,'mFloSupAirSet',0,'supFanOn',0,'mode',0,'OptiFlag',0,'predicted_power',0);
SuperCtrlSigField=fieldnames(SuperCtrlSig_GEB);
MPC_KalFil_status=struct('DocType','MPC_KalFil_status','Timestep',0,'Time',0,...
    'Tz_kf',0,'Tw_kf',0,'To_kf',0);
MPC_KalFil_statusField=fieldnames(MPC_KalFil_status);
MPC_debugdata=struct('DocType','MPC_debugdata','Timestep',0,'Time',0,...
                'mode',0,'q_hvac_ch',0,'b_chc_ch',0,'b_chd_ch',0,'b_isd_ch',0,'q_chd_ch',0,'q_isd_ch',0,'Tz_pred_ch',0,'soc_pred_ch',0,'P_pred_ch',0);
MPC_debugdata_Field=fieldnames(MPC_debugdata);
[T] = xlsread('Time.xlsx', 1,'B1')+15*60;
stop_time = T+2;
end
%% obtain Simulink stop time
% current_system = get_param(0, 'CurrentSystem');
% stop_time_as_str = get_param(current_system, 'StopTime');
% stop_time = str2double(stop_time_as_str);
% [T] = xlsread('Time.csv', 1,'A1');
% stop_time = T+15*60;
%% insert supervisory signals to DB 
if block.InputPort(1).Data(end)>=stop_time
    SuperCtrlSig_GEB.Timestep=xlsread('Time.xlsx', 1,'A1');
    SuperCtrlSig_GEB.Time=xlsread('Time.xlsx', 1,'B1');
    MPC_KalFil_status.Timestep=xlsread('Time.xlsx', 1,'A1');
    MPC_KalFil_status.Time=xlsread('Time.xlsx', 1,'B1');
    MPC_debugdata.Timestep=xlsread('Time.xlsx', 1,'A1');
    MPC_debugdata.Time=xlsread('Time.xlsx', 1,'B1');
%     block.InputPort(1).Data(3)=block.InputPort(1).Data(3)+...
%         0.001*SuperCtrlSig_GEB.Timestep;
    for i=1:10
        SuperCtrlSig_GEB.(SuperCtrlSigField{i+4})=block.InputPort(1).Data(i);
    end
    
    for j=1:10
        MPC_debugdata.(MPC_debugdata_Field{j+3})=block.InputPort(1).Data(j+10);
    end
    
    SuperCtrlSig_GEB.TConWatSupSet=SuperCtrlSig_GEB.TConWatSupSet-273.15;
    SuperCtrlSig_GEB.TChiWatSupSet=SuperCtrlSig_GEB.TChiWatSupSet-273.15;
    SuperCtrlSig_GEB.TSupAirSet=SuperCtrlSig_GEB.TSupAirSet-273.15;
    SuperCtrlSig_GEB.TZonCooSet=SuperCtrlSig_GEB.TZonCooSet-273.15;
%     if SuperCtrlSig_GEB.Timestep==600
%         pause(1000);
%     end

    MPC_KalFil_status.Tz_kf=block.InputPort(1).Data(end-3);
    MPC_KalFil_status.Tw_kf=block.InputPort(1).Data(end-2);
    MPC_KalFil_status.To_kf=block.InputPort(1).Data(end-1);

    insert(conn,CollName,SuperCtrlSig_GEB);
    insert(conn,CollName,MPC_KalFil_status);
    insert(conn,CollName,MPC_debugdata);
    clear all
else
    stop_time=stop_time-1;
end
%end Outputs

%%
%% Update:
%%   Functionality    : Called to update discrete states
%%                      during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlUpdate
%%
function Update(block)

% block.Dwork(1).Data = block.InputPort(1).Data;

%end Update

%%
%% Derivatives:
%%   Functionality    : Called to update derivatives of
%%                      continuous states during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlDerivatives
%%
function Derivatives(block)

%end Derivatives

%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%   Required         : Yes
%%   C MEX counterpart: mdlTerminate
%%
function Terminate(block)

%end Terminate

