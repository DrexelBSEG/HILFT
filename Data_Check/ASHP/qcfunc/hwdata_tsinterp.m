function hdata_interp = hwdata_tsinterp(hdata)
% This function add an additional column of smaller timesteps that filled
% the gap between the simulation timestep
Sim_Timestep = hdata.("Sim_Timestep");
% initialize
rec_timestep = -1;
rec_row = 0;
for i=1:length(Sim_Timestep)
    if i == 1
        % assign current row value
        Sim_Timestep_interp(i) = Sim_Timestep(i);
        rec_row = i;
        rec_timestep = Sim_Timestep(i);
    end    
    if Sim_Timestep(i) > rec_timestep && i > 1
        % assign current row value
        Sim_Timestep_interp(i) = Sim_Timestep(i);
        % find how many steps to be interpolate in between
        int_step = i - rec_row;
        % determine the size of interpolate value
        int = (Sim_Timestep(i)-Sim_Timestep(rec_row))/(i-rec_row);
        % dteremine previous values
        for j = i:-1:i-int_step+2
            Sim_Timestep_interp(j-1) = Sim_Timestep_interp(j)-int;
        end
       rec_row = i;
       rec_timestep = Sim_Timestep(i);
    end
    if Sim_Timestep(i) >= 1440
        % assign current row value
        Sim_Timestep_interp(i) = Sim_Timestep(i);        
    end
end
hdata_interp = hdata;
hdata_interp.Sim_Timestep_interp = Sim_Timestep_interp';
end


