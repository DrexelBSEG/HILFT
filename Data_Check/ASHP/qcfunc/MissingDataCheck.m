function Missing_Data_Check = MissingDataCheck(T,ContinueMissingThreshold,MissingRateThreshold)
%MISSINGDATACHECK Summary of this function goes here
%   Detailed explanation goes here
missing = ismissing(T,{'',NaN,9999});   % missing data matrix
missing_sum = sum(missing==1);    % total missing data of each column
missing_rate = missing_sum/height(T); % missing data rate of each column
if any(missing_sum > ContinueMissingThreshold) % if there are x-min missing data
    % check if the data is continue missing
    missing_col = find(missing_sum > ContinueMissingThreshold);  
    k = 0;
    for i=1:length(missing_col)
        if any(movmean(missing(:,missing_col(i)),ContinueMissingThreshold)>0.9999999999)
            k = k+1;
            Missing_Data_Check.continue_missing_field{k} = T.Properties.VariableNames{missing_col(i)};
        end
    end
    if k<1
        Missing_Data_Check.continue_missing_flag = 'Pass';
    else
        Missing_Data_Check.continue_missing_flag = 'Fail';
    end
else
	Missing_Data_Check.continue_missing_flag = 'Pass';    
end

if any(missing_rate > MissingRateThreshold)
    missing_col = find(missing_rate > MissingRateThreshold); 
    for i=1:length(missing_col)
        Missing_Data_Check.significant_missing_field{i} = T.Properties.VariableNames{missing_col(i)};
    end
    Missing_Data_Check.significant_missing_flag = 'Fail';
else
    Missing_Data_Check.significant_missing_flag = 'Pass';   
end


