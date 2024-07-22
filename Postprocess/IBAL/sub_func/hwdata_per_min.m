function [scaledData2_sim,processData2_sim,delay] = hwdata_per_min(scaledData2,processData2,ts_start,ts_end)
%% Note
% hwdata: hardware data to be worked on, in structure format
% hwdata_sent: hardware data with the simulate timestep recorded in it, in
% structure format
% Measurements: measurements received by the simulation during the
% communication
% hwdata_sent: hardware data of the rows with data sent to the simulation
%% Main code
% initialize index
i = 0;
% go through timestep one by one
for timestep=ts_start:ts_end
    i = i+1;
    % locate rows of hardware data with the same timestep
    rows = find([processData2.comms_timestep]==timestep);
    if ~isempty(rows)
        % if found, use the current rows
        j = rows(1);
        temp1 = scaledData2(j);    % copy row
        temp1.timestep_sent = timestep;  % add the current timestep to the structure
        temp1.flag = 1;  % flag this time step
        scaledData2_sim(i) = temp1; % copy to the new structure
        temp2 = processData2(j);    % copy row
        temp2.timestep_sent = timestep;  % add the current timestep to the structure
        temp2.flag = 1;  % flag this time step
        processData2_sim(i) = temp2; % copy to the new structure
        delay(i,1) = 999;    % communication delay set to 999         
    else
        % if no row contain the current time step, hardware is in the
        % skippoing mode, Measurements is receiving the same data from
        % hardware side. Assuming that the timestep 0 shoud always exist,
        % simply repeat the previous row
        if exist('scaledData2_sim','var')
            scaledData2_sim(i) = scaledData2_sim(timestep);
            scaledData2_sim(i).timestep_sent = timestep;
            processData2_sim(i) = processData2_sim(timestep);
            processData2_sim(i).timestep_sent = timestep;
        else
            scaledData2_sim(i) = scaledData2(1);
            scaledData2_sim(i).timestep_sent = 0;
            scaledData2_sim(i).flag = 0;
            processData2_sim(i) = processData2(1);
            processData2_sim(i).timestep_sent = 0;   
            processData2_sim(i).flag = 0;
        end
    end
end
end

