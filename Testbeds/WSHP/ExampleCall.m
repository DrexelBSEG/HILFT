clc
clear all
poolobj = gcp('nocreate');
delete(poolobj);
myCluster = parcluster('local');
delete(myCluster.Jobs)

par_dir = fileparts(strcat(pwd,'\callSim.m'));
addpath(strcat(par_dir,'\OBM'));
addpath(strcat(par_dir,'\OBM\AirflowANNmodel'));
addpath(strcat(par_dir,'\DB'));
addpath(strcat(par_dir,'\VB'));
addpath(strcat(par_dir,'\CTRL'));
addpath(strcat(par_dir,'\CTRL\MPC'));
addpath(fullfile(par_dir, '\CTRL\MPC\casadi-windows-v3.5.5')); % add casadi to path
addpath('C:\gurobi1000\win64\matlab')
addpath(strcat(par_dir,'\CTRL\MPC\Disturbances\Atlanta_2015')); 
%% Please provide the simulation time period
T = 86400; % length of the simulation period 
ntimestep=T/60; % total number of time step
for timestep=0:ntimestep
    %% At every iteration,update measurements
    HardwareTime = 0.0001*timestep; % Please assign a unique hardware clock time this variable. It can be an index number or the actual hardware time
    % Please refer to the notes in callSim for the meaning of each inputs
    Meas=[0.1,18,0.01,27,0.0095,18,300];
    Meas_MPC=[17.8,17.8,17.8,17.8,0];
    %% Call Simulation
    [ZoneInfo,CtrlSig,MPC_DebugData]=callSim(HardwareTime,timestep,Meas,Meas_MPC);
end

% save all data to .mat file
DataDL;