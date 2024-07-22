clear all
clc

% Add path
addpath(strcat(pwd,'/sub_func'));

% Read the dictionary file into a MATLAB table
dict_table = readtable('post_dict.xlsx');

% Define information for grid signals
wholeday = [1:1440];

% peak period
%-------------------------------------------------------------
%              |  Atlanta  |  Buffalo  |  NewYork  |  Tucson  |
%--------------------------------------------------------------
% winter       |  NA          5pm-8pm     12pm-8pm    6am-10am|
%              |                                      5pm-9pm |
% shoulder     |  NA          NA          11am-7pm    5am-9am |
%              |                                      4pm-8pm |
% typ summer   |  1pm-6pm     10am-4pm    11am-7pm    1pm-7pm |
% extrm summer |  1pm-6pm     10am-4pm    11am-7pm    1pm-7pm |
%-------------------------------------------------------------
peak = {[13*60+1:18*60],[17*60+1:20*60],[12*60+1:20*60],[[6*60+1:10*60],[17*60+1:21*60]];... % winter
    [13*60+1:18*60],[16*60+1:19*60],[11*60+1:19*60],[[5*60+1:9*60],[16*60+1:20*60]];... % shoulder
    [13*60+1:18*60],[10*60+1:16*60],[11*60+1:19*60],[13*60+1:19*60];... % typical summer
    [13*60+1:18*60],[10*60+1:16*60],[11*60+1:19*60],[13*60+1:19*60];};  % extreme summer

% time-of-use price
%---------------------------------------------------------------------------------------------
%              |  Atlanta           |  Buffalo          |  NewYork       |  Tucson            |
%---------------------------------------------------------------------------------------------
% winter       |  offpeak:0.074646     offpeak:0.0232      offpeak:8.37     offpeak:0.025651  |
%              |                       shoulder:0.0308     peak:16.56       peak:0.038010     |      
%              |                       peak:0.0332                                            |
% shoulder     |  offpeak:0.074646     offpeak:0.0232      offpeak:8.37     offpeak:0.025651  |
%              |                                           peak:16.56       peak:0.038010     |
%              |                                                                              |
% typ summer   |  offpeak:0.074646     offpeak:0.0298      offpeak:8.37     offpeak:0.025609  |
%              |  peak:0.16923         shoulder:0.0409     peak:21.54       peak:0.071322     |
%              |                       peak:0.113                                             |
% extrm summer |  offpeak:0.074646     offpeak:0.0298      offpeak:8.37     offpeak:0.025609  |
%              |  peak:0.16923         shoulder:0.0409     peak:21.54       peak:0.071322     |
%              |                       peak:0.113                                             |
%---------------------------------------------------------------------------------------------
tou = cell(size(peak));

tou{1,1}(wholeday) = 0.074646;
tou{2,1}(wholeday) = 0.074646;
tou{3,1}(wholeday) = 0.074646; tou{3,1}(peak{3,1}) = 0.169230; 

tou{1,2}(wholeday) = 0.0232; tou{1,2}([8*60+1:19*60]) = 0.0308; tou{1,2}(peak{1,2}) = 0.0332;
tou{2,2}(wholeday) = 0.0232;
tou{3,2}(wholeday) = 0.0298; tou{3,2}([7*60+1:19*60]) = 0.0409; tou{3,2}(peak{3,2}) = 0.113;

tou{1,3}(wholeday) = 8.37; tou{1,3}(peak{1,3}) = 16.56;
tou{2,3}(wholeday) = 8.37; tou{2,3}(peak{2,3}) = 16.56;
tou{3,3}(wholeday) = 8.37; tou{3,3}(peak{3,3}) = 21.54;

tou{1,4}(wholeday) = 0.025651; tou{1,4}(peak{1,4}) = 0.038010;
tou{2,4}(wholeday) = 0.025651; tou{2,4}(peak{2,4}) = 0.038010;
tou{3,4}(wholeday) = 0.025609; tou{3,4}(peak{3,4}) = 0.071322;

for j=1:size(tou,2)
    tou{4,j} = tou{3,j};
end

% Get the list of all .mat files in the 'raw_data' subfolder
mat_files = dir('raw_data/*.mat');

%% Loop through each .mat file
for i = 1:length(mat_files)
    
    disp(i);
    
    % Get the file name with the relative path
    file_name = fullfile(mat_files(i).folder, mat_files(i).name);
    
    % Load the .mat file into 'data'
    raw_data = load(file_name);
    
    % Read settings 
    % Location
    switch raw_data.settings.Location(1)
        case 1
            Location = 'Atlanta';
        case 2
            Location = 'Buffalo';
        case 3
            Location = 'NewYorkCity';
        case 4
            Location = 'Tucson';
        otherwise
            Location = 'NONE';
    end
    % GEB scenario
    switch raw_data.settings.GEB_case(1)
        case 1
            GEB = 'Eff';
        case 2
            GEB = 'Shed';
        case 3
            GEB = 'Shift';
        case 4
            GEB = 'Mod';
        otherwise
            GEB = 'NONE';
    end
    % Variation
    var_mat = [raw_data.settings.SeasonType(1),...
       raw_data.settings.Control_method(1),...
       raw_data.settings.STD(1),...
       raw_data.settings.occ_dense(1),...
       raw_data.settings.occ_energysaving(1),...
       raw_data.settings.TES(1)];
    if all(var_mat == [4 0 1 0 0 0])
       Variation = 'Default';
    elseif all(var_mat == [2 0 1 0 0 0])
       Variation = 'TypShldr';
    elseif all(var_mat == [3 0 1 0 0 0])
       Variation = 'ExtrmSum';         
    elseif all(var_mat == [1 0 1 0 0 0])
       Variation = 'ExtrmWin';  
    elseif all(var_mat == [4 1 1 0 0 0])
       Variation = 'MPC'; 
    elseif all(var_mat == [4 0 2 0 0 0])
       Variation = 'STD2019';
    elseif all(var_mat == [4 0 1 1 0 0])
       Variation = 'DenseOcc';
    elseif all(var_mat == [4 0 1 0 1 0])
       Variation = 'EnergySave';
    elseif all(var_mat == [4 0 1 0 0 1])
       Variation = 'TES';
    elseif all(var_mat == [4 1 1 0 0 1])
       Variation = 'MPC&TES';
    else
       Variation = 'NONE';
    end

    % Test date
    parts = strsplit(mat_files(i).name, '_');
    test_date = parts{end-1};
    test_date_formatted = datetime(test_date, 'InputFormat', 'MMddyyyy');
    test_date_formatted = datestr(test_date_formatted, 'mm/dd/yyyy');

    % Save test date
    [test_matrix_i, test_matrix_j] = test_matrix_index(Location, GEB, Variation);
    test_matrix{test_matrix_i, test_matrix_j} = test_date_formatted;
    
    % Modify format if broken
    raw_data.Measurements = raw_data.Measurements(1:1441,:);
    raw_data.SimData = raw_data.SimData(1:1441,:);
    if iscell(raw_data.SimData)
        for j = 1:length(raw_data.SimData)
            temp(j,1) = raw_data.SimData{j,1};
        end
        raw_data.SimData = temp;
    end
    
    % Sample hardware data
    hdata_name = fieldnames(raw_data.HardwareData);
    raw_data.hdata = eval(['raw_data.HardwareData.' hdata_name{1}]);
    [raw_data.hdata_sim,~] = hwdata_sent(raw_data.hdata,raw_data.Measurements);
    
    % Remove first row
    Measurement = raw_data.Measurements(2:1441,:);
    SupvCtrlSig = raw_data.SupvCtrlSig(2:1441,:);
    SimData = raw_data.SimData(2:1441,:);
    hdata_sim = raw_data.hdata_sim(2:1441,:);
    EPlusOutput = raw_data.EPlusOutput(1441:end,:);
    OccupantMatrix = raw_data.OccupantMatrix(:,2:1441);
    
    % Date/Time (use EnergyPlus format)
    date_time = raw_data.EPlusOutput.('Date/Time')(1441:2880, :);
    dt = datetime(date_time{1200}, 'InputFormat', 'MM/dd HH:mm:ss');
    mm = month(dt);
    dd = day(dt);
 
    % Determine the season
    if (mm > 6 && mm < 9) || (mm == 6 && dd > 20) || (mm == 9 && dd <= 20)
        season = 'summer';
    elseif (mm > 9 && mm < 12) || (mm == 9 && dd > 20) || (mm == 12 && dd <= 20)
        season = 'fall';
    elseif (mm > 12 || mm < 3) || (mm == 12 && dd > 20) || (mm == 3 && dd <= 20)
        season = 'winter';
    elseif (mm > 3 && mm < 6) || (mm == 3 && dd > 20) || (mm == 6 && dd <= 20)
        season = 'spring';
    end

    % Create postprocessed table
    post_data = table(date_time, 'VariableNames', {'date_time'});

%---System data     

    % Find the last row before occupant data
    row_last_system_data = find(strcmp(dict_table.POST_LABEL, 'grid_signal_price'));

    % Measurements
    for j = 1:row_last_system_data
        
        % Read labels
        raw_label = dict_table.RAW_LABEL(j);
        post_label = dict_table.POST_LABEL(j);
        raw_data_struct = dict_table.RAW_DATA_STRUCT(j);
        
        % Skip if label is 'NA'
        if strcmp(raw_label{1}, 'NA')
            post_data.(post_label{1}) = cell(height(post_data),1);
            continue;
        end
        
        % Hardware data
        if strcmp(raw_data_struct{1}, 'HardwareData')
            post_data.(post_label{1}) = hdata_sim.(raw_label{1});
        % Simulation data (zone and outdoor temperature)
        elseif strcmp(raw_data_struct{1}, 'SimData')
            temp_sim = [SimData.(raw_label{1})]';
            % conver to F
            post_data.(post_label{1}) = round(temp_sim*1.8 + 32, 1);
        end 
        
    end
    
    % Simulated dewpoint converted from simulated humidity ratio using local pressure
    local_pres = [post_data.local_pres];
    w_z = [SimData.w_z]';
    w_out = [SimData.w_out]';
    post_data.zn_temp_dp_sim = w2tdp_ashrae2021_si(inhg2kpa(local_pres), w_z) * 1.8 + 32;
    post_data.oa_temp_dp_sim = w2tdp_ashrae2021_si(inhg2kpa(local_pres), w_out) * 1.8 + 32;
    post_data.zn_temp_dp_spt_emu = post_data.zn_temp_dp_sim;
    post_data.oa_temp_dp_spt_emu =  post_data.oa_temp_dp_sim;
    
    % Create a new column 'stat' in post_data table
    post_data.stat = zeros(height(post_data), 1);
    if strcmp(Variation, 'ExtrmWin')
        post_data.stat(301:1260) = 1;
    else
        post_data.stat(361:1320) = 1;
    end
    
    % Create a new column 'stag' in post_data table
    post_data.stg = zeros(height(post_data), 1);
    post_data.stg(post_data.sa_flow > 500) = 1;
    post_data.stg(post_data.sa_flow > 1000) = 2;  
    
    % Create a new column 'gird_signal_type' in post_data table
    if strcmp(GEB, 'Shed')
        grid_signal_type = 1;
    elseif strcmp(GEB, 'Shift') 
        if strcmp(Location, 'NewYorkCity')
            grid_signal_type = 3;
        else
            grid_signal_type = 2;
        end
    else
        grid_signal_type = 0;
    end 
    post_data.grid_signal_type = repmat(grid_signal_type, height(post_data), 1);
    
    % Create a new column 'gird_signal_shed' in post_data table
    peak_table_loc = [raw_data.settings.SeasonType(1),raw_data.settings.Location(1)];
    post_data.grid_signal_shed = repmat(-9999, height(post_data), 1);    
    if strcmp(GEB, 'Shed')
        post_data.grid_signal_shed (:)= 0; 
        post_data.grid_signal_shed (peak{peak_table_loc(1), peak_table_loc(2)}')= 1; 
    end

    % Create a new column 'gird_signal_price' in post_data table
    tou_table_loc = [raw_data.settings.SeasonType(1),raw_data.settings.Location(1)];
    post_data.grid_signal_price = repmat(-9999, height(post_data), 1);    
    if strcmp(GEB, 'Shift')
        post_data.grid_signal_price = tou{tou_table_loc(1), tou_table_loc(2)}';
    end  
    
    % Loop through system data to set output precision
    for j = 1:row_last_system_data
        
        % Read data labels and desired precision
        post_label = dict_table.POST_LABEL(j);
        pc = dict_table.PRECISION(j);
        
%         % Update output table
%         post_data.(post_label{1}) = arrayfun(@(x) sprintf(['%.' num2str(pc) 'f'], x), post_data.(post_label{1}), 'UniformOutput', false);
   
        % Convert to string with specified precision or handle -9999
        formattedValues = arrayfun(@(x) ...
            sprintf(['%.' num2str(pc) 'f'], x), post_data.(post_label{1}), 'UniformOutput', false);

        % Find indices of -9999 values
        indicesOfMinus9999 = post_data.(post_label{1}) == -9999;

        % Correct those values to have no decimal point
        formattedValues(indicesOfMinus9999) = arrayfun(@(x) sprintf('%d', x), ...
            post_data.(post_label{1})(indicesOfMinus9999), 'UniformOutput', false);

        % Assign back to the final table
        post_data.(post_label{1}) = formattedValues;  
        
    end
    
%---Occupant data    
    
    % Max number of occupants
    occ_num_max = size(OccupantMatrix(1).OccupantMatrix,1);
    
    % Loop through all occupants
    for j = 1:occ_num_max
 
        % Loop through all time steps
        for k = 1:1440
            
            % Gender
            Gender(k,1) = OccupantMatrix(k).OccupantMatrix(j).Gender;
            
            % Acceptability
            if strcmp(season,'summer')
                low_index = 1;
                up_index = 2;
            elseif strcmp(season,'fall')
                low_index = 3;
                up_index = 4;
            elseif strcmp(season,'winter')
                low_index = 5;
                up_index = 6;
            elseif strcmp(season,'spring')
                low_index = 7;
                up_index = 8;
            end
            accept_low(k,1) = OccupantMatrix(k).OccupantMatrix(j).AcceptabilityVector(low_index);
            accept_up(k,1) = OccupantMatrix(k).OccupantMatrix(j).AcceptabilityVector(up_index);
                
            % Zone
            ZoneName(k,1) = 1;
            
            % Presense
            InOffice(k,1) = OccupantMatrix(k).OccupantMatrix(j).InOffice;    
            
            % Occupant location
            OccPosition = InOffice(k,1) * OccupantMatrix(k).OccupantMatrix(j).OccPosition;
            
            % x-cor
            loc_x(k,1) = OccPosition(1);
            % y-cor
            loc_y(k,1) = OccPosition(2);
            
            % Thermal sensation
            PMVdraw(k,1) = OccupantMatrix(k).OccupantMatrix(j).PMVdraw;
            
            % Met
            MetabolicRate(k,1) = OccupantMatrix(k).OccupantMatrix(j).MetabolicRate;
            
            % Clothing level
            CurrentClothing(k,1) = OccupantMatrix(k).OccupantMatrix(j).CurrentClothing;

            % Comfort
            PMVact(k,1) = OccupantMatrix(k).OccupantMatrix(j).PMVact;

            % Personal heater
            ph(k,1) = abs(InOffice(k,1) * OccupantMatrix(k).OccupantMatrix(j).BehaviorStatesVector(5));        
            ph_power(k,1) = ph(k,1) * 1200;
            
            % Personal fan
            pf(k,1) = abs(InOffice(k,1) * OccupantMatrix(k).OccupantMatrix(j).BehaviorStatesVector(6));
            pf_power(k,1) = pf(k,1) * 15;
            
            % Thermostat
            if OccupantMatrix(k).OccupantMatrix(j).WhichPMVact == 7
                spt_change(k,1) = - InOffice(k,1) * PMVact(k,1) * 2;
            else
                spt_change(k,1) = 0;
            end            

            % Drink
            if OccupantMatrix(k).OccupantMatrix(j).WhichPMVact == 3
                drink(k,1) = - InOffice(k,1) * PMVact(k,1);
            else
                drink(k,1) = 0;
            end   

            % Activity
            if OccupantMatrix(k).OccupantMatrix(j).WhichPMVact == 3
                activity(k,1) = InOffice(k,1);
            else
                activity(k,1) = 0;
            end
        
        end
        
        % Create field name
        gender_field_name = sprintf('occ%02d_gender', j);
        accept_low_field_name = sprintf('occ%02d_accept_low', j);
        accept_up_field_name = sprintf('occ%02d_accept_up', j);
        zn_field_name = sprintf('occ%02d_zn', j);
        pres_field_name = sprintf('occ%02d_pres', j);
        loc_x_field_name = sprintf('occ%02d_loc_x', j);
        loc_y_field_name = sprintf('occ%02d_loc_y', j);
        sen_field_name = sprintf('occ%02d_sen', j);
        comfort_field_name = sprintf('occ%02d_comfort', j);
        met_field_name = sprintf('occ%02d_met', j);
        clo_field_name = sprintf('occ%02d_clo', j);
        ph_field_name = sprintf('occ%02d_ph', j);
        ph_power_field_name = sprintf('occ%02d_ph_power', j);
        pf_field_name = sprintf('occ%02d_pf', j);
        pf_power_field_name = sprintf('occ%02d_pf_power', j);
        spt_field_name = sprintf('occ%02d_spt', j);
        drink_field_name = sprintf('occ%02d_drink', j);
        act_field_name = sprintf('occ%02d_act', j);
        
        % Store occupant data label
        occ_data_label = {gender_field_name,...
                          accept_low_field_name,...
                          accept_up_field_name,...
                          zn_field_name,...
                          pres_field_name,...
                          loc_x_field_name,...
                          loc_y_field_name,...
                          sen_field_name,...
                          comfort_field_name,...
                          met_field_name,...
                          clo_field_name,...
                          ph_field_name,...
                          ph_power_field_name,...
                          pf_field_name,...
                          pf_power_field_name,...
                          spt_field_name,...
                          drink_field_name,...
                          act_field_name};
        
        % Add occupant data to post_data table
        post_data.(gender_field_name) = Gender;
        post_data.(accept_low_field_name) = accept_low;
        post_data.(accept_up_field_name) = accept_up;
        post_data.(zn_field_name) = ZoneName;
        post_data.(pres_field_name) = InOffice;
        post_data.(loc_x_field_name) = loc_x;
        post_data.(loc_y_field_name) = loc_y;
        post_data.(sen_field_name) = PMVdraw;
        post_data.(comfort_field_name) = PMVact;
        post_data.(met_field_name) = MetabolicRate;
        post_data.(clo_field_name) = CurrentClothing;
        post_data.(ph_field_name) = ph;
        post_data.(ph_power_field_name) = ph_power;
        post_data.(pf_field_name) = pf;
        post_data.(pf_power_field_name) = pf_power;
        post_data.(spt_field_name) = spt_change;
        post_data.(drink_field_name) = drink;
        post_data.(act_field_name) = activity;
        
        % Loop through all occupant data labels
        for k = 1:length(occ_data_label)
            
            % Read data labels
            post_label = occ_data_label(k);
            
            % Find corresponding row in dict_table
            pc = dict_table.PRECISION(row_last_system_data + k);
            
            % Update post_data table to desired precision
            post_data.(post_label{1}) = arrayfun(@(x) sprintf(['%.' num2str(pc) 'f'], x), post_data.(post_label{1}), 'UniformOutput', false);
            
        end
        
    end

%---Output post data    
    
    % Construct the new directory path
    new_dir_path = fullfile('post_data/data', Location, GEB, Variation);

    % Create new directory if it doesn't exist
    if ~exist(new_dir_path, 'dir')
        mkdir(new_dir_path);
    end
     
    % Save the processed table as a CSV file in the new folder
    csv_file_name = 'data.csv';
    csv_file_path = fullfile(new_dir_path, csv_file_name);
    writetable(post_data, csv_file_path);

    % Construct the new directory path in raw folder
    new_dir_path = fullfile('post_data/raw', Location, GEB, Variation);

    % Create new directory if it doesn't exist
    if ~exist(new_dir_path, 'dir')
        mkdir(new_dir_path);
    end
    
    % Copy the raw data file to the raw folder
    copyfile(file_name, fullfile(new_dir_path, 'raw.mat'));    
end

%% Output metadata

% Select the columns and create a new table
metadata = dict_table(:, {'POST_LABEL', 'DESCRIPTION', 'UNIT', 'UNCERTAINTY'});

% Rename the 'post_label' column to 'label'
metadata.Properties.VariableNames{'POST_LABEL'} = 'LABEL';

% Define the directory and file name
assets_dir = 'post_data/assets';
csv_file_name = 'metadata.csv';

% Ensure the directory exists
if ~exist(assets_dir, 'dir')
    mkdir(assets_dir);
end

% Construct the full file path
csv_file_path = fullfile(assets_dir, csv_file_name);

% Save metadata table as a CSV file
writetable(metadata, csv_file_path);

%% Save test matrix for comparison to make sure the correct data is used
% 
% % Get current date and time
% currentDateTime = datetime('now');
% 
% % Format the date and time as a string
% dateTimeStr = datestr(currentDateTime, 'yyyymmdd_HHMM');
% 
% % Create the filename with the current date and time
% filename = ['test_matrix_', dateTimeStr, '.xlsx'];
% 
% % Save the cell array to a CSV file with the timestamped filename
% writecell(test_matrix, filename);