function DBread_Meas_MPC(block)
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
block.InputPort(1).Dimensions        = 1;
block.InputPort(1).DatatypeID  = 0;  % double
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = true;

% Override output port properties
block.OutputPort(1).Dimensions       = [1,8]; 
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
persistent conn CollName Timestep Meas_MPC_query Meas_query SimData_query
%% initiate DB connection
if isempty(CollName)
    % database location
    DBName=load('DBLoc.mat').DBName;
    CollName=load('DBLoc.mat').CollName;
    % connect to the database
    conn = mongo('localhost',27017,DBName);
    
    % based on the timestep to read the measurements for MPC (YC 2023/01/31)
    Timestep=mod(block.InputPort(1).Data(end),86400)/60-15;
    Meas_MPC_query=find(conn,CollName,'Query',['{"Timestep":',...
        num2str(Timestep),',"DocType":"Measurements_MPC"}']);
    Meas_query=find(conn,CollName,'Query',['{"Timestep":',...
        num2str(Timestep),',"DocType":"Measurements"}']);
    SimData_query=find(conn,CollName,'Query',['{"Timestep":',...
        num2str(Timestep-1),',"DocType":"SimData"}']);
end
%% obtain measurements from DB
% Timestep=mod(block.InputPort(1).Data(end),86400)/60;

% Meas_MPC_query=find(conn,CollName,'Query','{"DocType":"Measurements_MPC"}');
% Meas_MPC_query=rmfield(Meas_MPC_query,{'x_id','DocType'});
% Meas_MPC_query_T=struct2table(Meas_MPC_query);
% Meas_MPC_query_T_sorted=sortrows(Meas_MPC_query_T,'Timestep','descend');
% Meas_MPC=table2array(Meas_MPC_query_T_sorted);
% 
% Meas_query=find(conn,CollName,'Query','{"DocType":"Measurements"}');
% Meas_query=rmfield(Meas_query,{'x_id','DocType'});
% Meas_query_T=struct2table(Meas_query);
% Meas_query_T_sorted=sortrows(Meas_query_T,'Timestep','descend');
% Meas=table2array(Meas_query_T_sorted);

% SimData_query=find(conn,CollName,'Query',['{"Timestep":',...
%                    num2str(Timestep),',"DocType":"SimData"}']);

% block.OutputPort(1).Data(1,:) = [Meas_query_T_sorted.m_CHW_sl(1),(Meas_query_T_sorted.T_chwst_cur(1))+273.15,...
%     ((Meas_MPC_query_T_sorted.ch1_e_in_rtd(1))-32)/1.8+273.15,(Meas_query_T_sorted.TES_inventory(1))*0.01,...
%      SimData_query{Timestep,1}.T_z1_ahu1,SimData_query{Timestep,1}.T_z2_ahu1,...
%     SimData_query{Timestep,1}.T_z1_ahu2,SimData_query{Timestep,1}.T_z2_ahu2];

block.OutputPort(1).Data(1,:) = [Meas_query.m_CHW_sl,(Meas_query.T_chwst_cur)+273.15,...
    ((Meas_MPC_query.ch1_e_in_rtd)-32)/1.8+273.15,(Meas_query.TES_inventory)*0.01,...
     SimData_query.T_z1_ahu1,SimData_query.T_z2_ahu1,...
    SimData_query.T_z1_ahu2,SimData_query.T_z2_ahu2];
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

