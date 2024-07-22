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
block.InputPort(1).Dimensions        = 15;
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
persistent conn CollName SuperCtrlSig_GEB SuperCtrlSigField stop_time x_opt x_optField MPC_DebugData MPC_DebugDataField
%% initiate DB connection
if isempty(CollName)
% database location
DBName=load('DBLoc.mat').DBName;
CollName=load('DBLoc.mat').CollName;
% connect to the database
conn = mongo('localhost',27017,DBName);
% field name
SuperCtrlSig_GEB=struct('DocType','SuperCtrlSig_GEB','Timestep',0,'Time',0,...
                    'FailFlag',0,'TZonCooSet',78,'TZonHeaSet',68,'OptiFlag',0);
SuperCtrlSigField=fieldnames(SuperCtrlSig_GEB);
x_opt=struct('DocType','x_opt','Timestep',0,'Time',0,...
    'x_opt1',0,'x_opt2',0,'x_opt3',0,'x_opt4',0);
x_optField=fieldnames(x_opt);

MPC_DebugData=struct('DocType','MPC_DebugData','Timestep',0,'Time',0,...
    'status',0,'T2_opt',0,'y_opt',0,'q_opt',0,'p_opt',0,'price',0,'Tub_i',0,'Tlb_i',0,'Tz_opt',0);
MPC_DebugDataField=fieldnames(MPC_DebugData);

stop_time = block.InputPort(1).Data(end);
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
    x_opt.Timestep=xlsread('Time.xlsx', 1,'A1');
    x_opt.Time=xlsread('Time.xlsx', 1,'B1');
    MPC_DebugData.Timestep=xlsread('Time.xlsx', 1,'A1');
    MPC_DebugData.Time=xlsread('Time.xlsx', 1,'B1');
    
    SuperCtrlSig_GEB.TZonCooSet=block.InputPort(1).Data(1);
    SuperCtrlSig_GEB.TZonHeaSet=20;
    
    if block.InputPort(1).Data(end-1)==0
        SuperCtrlSig_GEB.OptiFlag=1;
    else
        SuperCtrlSig_GEB.OptiFlag=0;
    end

    x_opt.x_opt1=block.InputPort(1).Data(2);
    x_opt.x_opt2=block.InputPort(1).Data(3);
    x_opt.x_opt3=block.InputPort(1).Data(4);
    x_opt.x_opt4=block.InputPort(1).Data(5);
    
    MPC_DebugData.status=block.InputPort(1).Data(6);
    MPC_DebugData.T2_opt=block.InputPort(1).Data(7);
    MPC_DebugData.y_opt=block.InputPort(1).Data(8);
    MPC_DebugData.q_opt=block.InputPort(1).Data(9);
    MPC_DebugData.p_opt=block.InputPort(1).Data(10);
    MPC_DebugData.price=block.InputPort(1).Data(11);
    MPC_DebugData.Tub_i=block.InputPort(1).Data(12);
    MPC_DebugData.Tlb_i=block.InputPort(1).Data(13);
    MPC_DebugData.Tz_opt=block.InputPort(1).Data(14);
    
    insert(conn,CollName,SuperCtrlSig_GEB);
    insert(conn,CollName,x_opt);
    insert(conn,CollName,MPC_DebugData);
    clear all
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

