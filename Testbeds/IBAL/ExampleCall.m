clc
clear all
poolobj = gcp('nocreate');
delete(poolobj);
myCluster = parcluster('local');
delete(myCluster.Jobs)
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
par_dir = fileparts(strcat(pwd,'\callSim.m'));
addpath(strcat(par_dir,'\CTRL\MPC'));
addpath(fullfile(par_dir, '\CTRL\MPC\casadi-windows-v3.5.5')); % add casadi to path
addpath(fullfile(par_dir, '\CTRL\MPC\load-shifting')); % add casadi to path
addpath('C:\gurobi1000\win64\matlab')
addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_a'));
addpath(fullfile(par_dir, '\CTRL\MPC\system-identification_a\low-level'));

%% Please provide the simulation time period
T = 86400; % length of the simulation period 
ntimestep=T/60; % total number of time step
for timestep=0:ntimestep
    %% At every iteration,update measurements
    HardwareTime = 0.0001; % Please assign index number of the hardware data to this variable
    % Please refer to the notes in callSim for the meaning of each inputs
    Meas=[0,18+timestep/10000,0.009,27+0.1*randi([-10,10],1,1),0.0095,...
        0,18.1+timestep/10000,0.0091,27+0.1*randi([-10,10],1,1),0.00951,...
        0,18.2+timestep/10000,0.0092,27+0.1*randi([-10,10],1,1),0.00952,...
        0,18.3+timestep/10000,0.0093,27+0.1*randi([-10,10],1,1),0.00953,...
        200,60,7,8,0,0,...
        398.5,12.8,5,10,13,...
        200.1,60.1,3,4,0,0,...
        398.5,12.8,5,10,13,...
        100,3,0.22+0.02*randi([-10,10],1,1),8,8,8,6.7+0.02*randi([-10,10],1,1),379,...
        50+2*randi([-10,10],1,1),1,28,25,25,600];
    
    Meas_MPC=[56,30,100,18.1+0.1*randi([-10,10],1,1),40,100,100,...
        56,30,100,30,40,100,100,...
        30,40,100,50,...
        300,500,100,100,100,...
        30,50,100,50,30,500,500,100,...
        30,50,100,50,30,500,500,100,...
        100,200,300,400];
    %% Call Simulation
    [ZoneInfo,CtrlSig]=callSim(HardwareTime,timestep,Meas,Meas_MPC);
end

% save all data to .mat file
DataDL;