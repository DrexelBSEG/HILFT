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
addpath(fullfile(par_dir, '\CTRL\MPC\load-shifting'));
addpath(fullfile(par_dir, '\CTRL\MPC\load-shifting\cooling-only'));
addpath('C:\gurobi1000\win64\matlab')
addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_a\cooling'))); % add cooling and subfolders to path
addpath(genpath(fullfile(par_dir, 'CTRL\MPC\system-identification_a')));
addpath(fullfile(par_dir, 'CTRL\MPC\system-identification_a\fan'))
%% add the path of virtual ASHP  
par_dir = fileparts(strcat(pwd,'\ExampleCall.m'));
addpath(strcat(par_dir,'\VirtualASHP'));
%% Please provide the simulation time period
T = 86400; % length of the simulation period 
ntimestep=T/60; % total number of time step
for timestep=0:ntimestep
    %% At every iteration,update measurements
    HardwareTime = 0.0001*timestep; % Please assign a unique hardware clock time this variable. It can be an index number or the actual hardware time
    % Please refer to the notes in callSim for the meaning of each inputs
    Meas=[0.1,18,0.01,22,0.0095,28,300];
    %% Call Simulation
    [ZoneInfo,CtrlSig]=callSim(HardwareTime,timestep,Meas);
end

% save all data to .mat file
DataDL;