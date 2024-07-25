function [scaledData2_sent,processData2_sent,delay] = hwdata_sent(scaledData2,processData2,Measurements)
%% Note
% hwdata: hardware data to be worked on, in structure format
% hwdata_sent: hardware data with the simulate timestep recorded in it, in
% structure format
% Measurements: measurements received by the simulation during the
% communication
% hwdata_sent: hardware data of the rows with data sent to the simulation
%% Main code
% initial value
sim_timestep = -1;
hw_select = 0;  
% go through hardware data one by one
% for i=1:length(scaledData2)
for i=1:length(processData2)    
    temp = processData2(i).comms_timestep;  % simulation timestep stored on the current row
    if (temp ~= sim_timestep)
        % if this timestep has not been worked on 
        sim_timestep = temp;
        % data received by the simulation
%         Ts1 = round(Measurements(sim_timestep+1).T_sup_vav1_ahu1,4);  % received z1 inlet air temp [C]
%         Tz1 = round(Measurements(sim_timestep+1).T_z1_ahu1,4);    % received z1 air temp [C]
%         Ts2 = round(Measurements(sim_timestep+1).T_sup_vav2_ahu1,4);  % received z3 inlet air temp [C]
%         Tz2 = round(Measurements(sim_timestep+1).T_z2_ahu1,4);    % received z3 air temp [C]
        Ts1 = Measurements(sim_timestep+1).T_sup_vav1_ahu1;  % received z1 inlet air temp [C]
        Tz1 = Measurements(sim_timestep+1).T_z1_ahu1;    % received z1 air temp [C]
        Ts2 = Measurements(sim_timestep+1).T_sup_vav2_ahu1;  % received z3 inlet air temp [C]
        Tz2 = Measurements(sim_timestep+1).T_z2_ahu1;    % received z3 air temp [C]
        received = [Ts1 Tz1 Ts2 Tz2];
        % compare the measurment of the current row with the data in
        % Measurements, if they are the same, keep going earlier step, if
        % not break for loop
        for row=i:-1:max(1,i-30)
%             Ts2_hard = round((scaledData2(row).vav4_out_rtd-32)/1.8,4);
%             Tz2_hard = round((scaledData2(row).zs4_out_rtd-32)/1.8,4);
%             Ts1_hard = round((scaledData2(row).vav3_out_rtd-32)/1.8,4);
%             Tz1_hard = round((scaledData2(row).zs3_out_rtd-32)/1.8,4);
            Ts1_hard = (scaledData2(row).vav3_out_rtd-32)/1.8;
            Tz1_hard = (scaledData2(row).zs3_out_rtd-32)/1.8;
            Ts2_hard = (scaledData2(row).vav4_out_rtd-32)/1.8;
            Tz2_hard = (scaledData2(row).zs4_out_rtd-32)/1.8;
            sent = [Ts1_hard Tz1_hard Ts2_hard Tz2_hard];
            % flag
            
            % find the row of which the measurements were sent to
            % simulation
            if any(abs(received-sent)<=1e-4)
                hw_select = hw_select+1;
                A = scaledData2(row);
                A.timestep_sent = sim_timestep;
                scaledData2_sent(hw_select) = A;
                B = processData2(row);
                B.timestep_sent = sim_timestep;
                processData2_sent(hw_select) = B;
                delay(hw_select) = i-row;
                break
            end
        end
    end
end
end

