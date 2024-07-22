function [index_i, index_j] = test_matrix_index(Location, GEB, Variation)

% Location index
if strcmp(Location, 'Atlanta')
    LOC_i = 1;
elseif strcmp(Location, 'Buffalo')
    LOC_i = 2;
elseif strcmp(Location, 'NewYorkCity')
    LOC_i = 3;
elseif strcmp(Location, 'Tucson')  
    LOC_i = 4;
else
    error('Invalid Location.');
end

% GEB index
if strcmp(GEB, 'Eff')
    GEB_i = 1;
elseif strcmp(GEB, 'Shed')
    GEB_i = 2;
elseif strcmp(GEB, 'Shift')
    GEB_i = 3;
elseif strcmp(GEB, 'Mod')
    GEB_i = 4;
else
    error('Invalid GEB.');
end

% Index i
index_i = (LOC_i-1) * 4 + GEB_i;

% Index j
if strcmp(Variation, 'Default')
    index_j = 1;
elseif strcmp(Variation, 'ExtrmSum')
    index_j = 2;
elseif strcmp(Variation, 'TypShldr')
    index_j = 3;
elseif strcmp(Variation, 'MPC')
    index_j = 4;        
elseif strcmp(Variation, 'STD2019')
    index_j = 5;  
elseif strcmp(Variation, 'DenseOcc')
    index_j = 6;  
elseif strcmp(Variation, 'EnergySave')
    index_j = 7;  
elseif strcmp(Variation, 'TES')
    index_j = 8;  
elseif strcmp(Variation, 'MPCTES')
    index_j = 9; 
elseif strcmp(Variation, 'LoadBalance')
    index_j = 10; 
else
    error('Invalid Variation.');
end

