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
    disp('Error');
end

% GEB index
if strcmp(GEB, 'Eff')
    GEB_i = 1;
elseif strcmp(GEB, 'Shed')
    GEB_i = 2;
elseif strcmp(GEB, 'Shift')
    GEB_i = 3;
else
    disp('Error');
end

% Index i
index_i = (LOC_i-1) * 3 + GEB_i;

% Index j
if strcmp(Variation, 'Default')
    index_j = 1;
elseif strcmp(Variation, 'ExtrmSum')
    index_j = 2;
elseif strcmp(Variation, 'TypShldr')
    index_j = 3;
elseif strcmp(Variation, 'ExtrmWin')
    index_j = 4;
elseif strcmp(Variation, 'MPC')
    index_j = 5;        
elseif strcmp(Variation, 'STD2019')
    index_j = 6;  
elseif strcmp(Variation, 'DenseOcc')
    index_j = 7;  
elseif strcmp(Variation, 'EnergySave')
    index_j = 8;  
elseif strcmp(Variation, 'TES')
    index_j = 9;  
elseif strcmp(Variation, 'MPC&TES')
    index_j = 10; 
else
    disp('Error');
end

