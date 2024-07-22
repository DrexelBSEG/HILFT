function denergy = kpi_energy_change(ref_demand,flex_demand,time)
    
ddemand_mean = mean(ref_demand) - mean(flex_demand);
denergy = ddemand_mean*time;

end