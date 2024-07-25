function data_new = wshp_data_preprocess(data)
%% modify data if necessary
data.Measurements = data.Measurements(1:1441,:);
data.SupvCtrlSig = data.SupvCtrlSig(1:1441,:);
data.SimData = data.SimData(1:1441,:);
if iscell(data.SimData)
    for k = 1:length(data.SimData)
        SimData_temp(k,1) = data.SimData{k,1};
    end
    data.SimData = SimData_temp;
end
data_new = data;
end

