function [scaledData2_sim,processData2_sim,delay] = hwdata_sent(scaledData2,processData2,Measurements)
%% Note
% hwdata: hardware data to be worked on, in structure format
% hwdata_sent: hardware data with the simulate timestep recorded in it, in
% structure format
% Measurements: measurements received by the simulation during the
% communication
% hwdata_sent: hardware data of the rows with data sent to the simulation
%% Main code
% go through data in Measurements one by one
for timestep=-239:length(Measurements)-240
	% data received by the simulation
    Ts1 = Measurements(timestep+240).T_sup_vav1_ahu1;     % received z1 inlet air temp [C]
    Tz1 = Measurements(timestep+240).T_z1_ahu1;           % received z1 air temp [C]
    Ts2 = Measurements(timestep+240).T_sup_vav2_ahu1;     % received z3 inlet air temp [C]
    Tz2 = Measurements(timestep+240).T_z2_ahu1;           % received z3 air temp [C]
    received = [Ts1 Tz1 Ts2 Tz2];
    % locate rows of hardware data with the same timestep
    rows = find([processData2.comms_timestep]==timestep & [processData2.comms_doe_mode]>0);
    if ~isempty(rows)
        % initialize recorder
        successfully_found = 0;
        % the measuremnts received for this time step, supposely, can be
        % found in the current row or some previous row. therefore, go back
        % at most 30 rows to see if the measurements can be found
        for j=rows(1):-1:max(1,rows(1)-30)
            % hardware data saved on the current row
            Ts1_hard = (scaledData2(j).vav3_out_rtd-32)/1.8;
            Tz1_hard = (scaledData2(j).zs3_out_rtd-32)/1.8;
            Ts2_hard = (scaledData2(j).vav4_out_rtd-32)/1.8;
            Tz2_hard = (scaledData2(j).zs4_out_rtd-32)/1.8;
            sent = [Ts1_hard Tz1_hard Ts2_hard Tz2_hard];
            % check weather it matches the data saved in Measurements
            if all(abs(received-sent)<=1e-4)
                % if match, record this row and break for loop
                temp1 = scaledData2(j);    % copy row
                temp1.timestep_sent = timestep;  % add the current timestep to the structure
                temp1.flag = 0;  % no flag needed
                scaledData2_sim(timestep+240) = temp1; % copy to the new structure
                temp2 = processData2(j);    % copy row
                temp2.timestep_sent = timestep;  % add the current timestep to the structure
                temp2.flag = 0;  % no flag needed
                processData2_sim(timestep+240) = temp2; % copy to the new structure
                delay(timestep+240,1) = rows(1)-j;    % record communication delay
                successfully_found = 1; 
                break                              
            end
        end
        % check recorder
        if (successfully_found < 1)
            % if not found, use the current rows
            j = rows(1);
            temp1 = scaledData2(j);    % copy row
            temp1.timestep_sent = timestep;  % add the current timestep to the structure
            temp1.flag = 1;  % flag this time step
            scaledData2_sim(timestep+240) = temp1; % copy to the new structure
            temp2 = processData2(j);    % copy row
            temp2.timestep_sent = timestep;  % add the current timestep to the structure
            temp2.flag = 1;  % flag this time step
            processData2_sim(timestep+240) = temp2; % copy to the new structure
            delay(timestep+240,1) = -1;    % communication delay set to -1         
        end
    else
        % if no row contain the current time step, it hardware is in the
        % skippoing mode, Measurements is receiving the same data from
        % hardware side. Assuming that the timestep 0 shoud always exist,
        % simply repeat the previous row
        if exist('scaledData2_sim','var')
            scaledData2_sim(timestep+240) = scaledData2_sim(timestep+239);
            scaledData2_sim(timestep+240).timestep_sent = timestep;
            processData2_sim(timestep+240) = processData2_sim(timestep+239);
            processData2_sim(timestep+240).timestep_sent = timestep;
        else
            scaledData2_sim(timestep+240) = scaledData2(1);
            scaledData2_sim(timestep+240).timestep_sent = 0;
            scaledData2_sim(timestep+240).flag = 0;
            processData2_sim(timestep+240) = processData2(1);
            processData2_sim(timestep+240).timestep_sent = 0;   
            processData2_sim(timestep+240).flag = 0;
        end
    end
end
end

