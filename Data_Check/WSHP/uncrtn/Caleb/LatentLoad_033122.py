
import numpy as np
import matplotlib.pyplot as plt
from nptdms import TdmsFile, TdmsGroup 

fname="Test_AtlEffDef_032922_2100"
tdms_file= TdmsFile.read(fname+".tdms")

with tdms_file:
    # Time Stamp
    Time_Stamp=tdms_file["References"]
    Time_Stamp=TdmsGroup.as_dataframe(Time_Stamp,scaled_data=False)
    
    # Measured Thermocouple Temperatures
    Mea_Temp = tdms_file["Mea_Temp"]
    Mea_Temp=TdmsGroup.as_dataframe(Mea_Temp,scaled_data=False)
    
    # Calculated Loads, Flowrate, & Humidity Values
    CalcResults=tdms_file["CalcResults"]
    CalcResults=TdmsGroup.as_dataframe(CalcResults,scaled_data=False)
    
    # BACnet Measurments
    BACnet=tdms_file["BACnet"]
    BACnet=TdmsGroup.as_dataframe(BACnet,scaled_data=False)
    
    # Simulation
    Simulation=tdms_file["Simulation"]
    Simulation=TdmsGroup.as_dataframe(Simulation,scaled_data=False)
    

# Channel List
## WSHP Water Temperatures
HP_Water_Inlet=Mea_Temp["NI1-T-0[°C]"]
HP_Water_Outlet=Mea_Temp["NI1-T-1[°C]"]

## WSHP Air Temperatures
Inlet_Temp_LT=Mea_Temp["NI1-T-12[°C]"]
Inlet_Temp_RT=Mea_Temp["NI1-T-13[°C]"]
Inlet_Temp_LB=Mea_Temp["NI1-T-14[°C]"]
Inlet_Temp_RB=Mea_Temp["NI1-T-15[°C]"]

HP_Air_Return_Temp=(Inlet_Temp_LT+Inlet_Temp_RT+Inlet_Temp_LB+Inlet_Temp_RB)/4 # Return Air Temperature

Outlet_Temp_LT=Mea_Temp["NI1-T-16[°C]"]
Outlet_Temp_RT=Mea_Temp["NI1-T-17[°C]"]
Outlet_Temp_LB=Mea_Temp["NI1-T-18[°C]"]
Outlet_Temp_RB=Mea_Temp["NI1-T-19[°C]"]

HP_Air_Supply_Temp=(Outlet_Temp_LT+Outlet_Temp_RT+Outlet_Temp_LB+Outlet_Temp_RB)/4 # Supply Air Temperature

## Humidity Values
Supply_RH=CalcResults["RH2 [%]"]
Supply_HR=CalcResults["HR2 [kg/kg]"]
Return_RH=CalcResults["RH1 [%]"]
Return_HR=CalcResults["HR1 [kg/kg]"]

## Flowrate
HP_Water_Flow_kgps=CalcResults["F2 [kg/s]"]
HP_Air_Flow_cfm=BACnet["BC_AFM_Favg [cfm]"]

## Loads & Misc Heatpump Status
Qa_sens=CalcResults["Q_sens_a [kW]"]
Qa_lat=CalcResults["Q_lat_a [kW]"]
HP_Power=BACnet["BC_WN_PwrSum [W]"]
T_zone=BACnet["BC_HP_Tzspt [°C]"]

## Simulation Outputs
Sim_ZT=Simulation["Sim_T_zone [°C]"]
Sim_ZRH=Simulation["Sim_RH_zone [%]"]
Sim_ZHR=Simulation["Sim_w_z [kg/kg]"]
Sim_Tw=Simulation["Sim_T_w [°C]"]

# Emualation Accuracy #########################################################
Time_Stamp=Time_Stamp.to_numpy(dtype=float)/1*10**-9 # Convert Time Stamp to numpy array
Occ_Start=300 # 5:00 AM in minutes
Occ_End=1260 # 9:00 PM in minutes
SimStep=Simulation['CurrentSimStep']
for i in range(len(SimStep)):
    if SimStep[i]==Occ_Start:
        i_start=i
        break
for i in range(len(SimStep)):
    if SimStep[i]==Occ_End:
        i_end=i

SimStep_new=SimStep[i_start:i_end]
Offset_Rows=len(SimStep_new)

time=np.zeros(len(Time_Stamp),dtype=float)
for i in (range(len(Time_Stamp)-1)):
    time[i+1]=Time_Stamp[i+1]-Time_Stamp[0]

## Numpy Conversions
HP_Air_Return_Temp=HP_Air_Return_Temp.to_numpy(dtype=float)
Sim_ZT=Sim_ZT.to_numpy(dtype=float)
Return_RH=Return_RH.to_numpy(dtype=float)
Sim_ZRH=Sim_ZRH.to_numpy(dtype=float)
V_a=HP_Air_Flow_cfm.to_numpy(dtype=float)*0.00047194745 # Volumetric Flowrate of Air (m^3/s)
Return_HR=Return_HR.to_numpy(dtype=float)
Supply_HR=Supply_HR.to_numpy(dtype=float)
Sim_ZHR=Sim_ZHR.to_numpy(dtype=float) # Simulated Humidity Ratio
Sim_LL=Simulation["Sim_Qlat [W]"].to_numpy(dtype=float)
Meas_LL=CalcResults["Q_lat_a [kW]"].to_numpy(dtype=float)*-1000

## Calculation Parameters
rho_a=1.177; # Density of air at ambient conditions (kg/m^3)
cp_a=1005; # Specific Heat of air at ambient conditions (J/kgK)
Pam=101325 # Ambient Pressure (Pa)
hfg=2464.635*10**3


# Uncertainty #################################################################
wT=1 # Deg C, T-Type Thermocouple Measurement Accuracy
wTC=wT/np.sqrt(16) # Deg C, TC Grid Measurement Accuracy
wRH_sup=3 #/np.sqrt(4)# %RH, RH Sensor Measurment Accuracy >90 %RH
wRH_ret=2 #/np.sqrt(4) # %RH, RH Sensor Measurement Accuracy <90 %RH


## Zone Humidity Ratio
### Saturation Pressure (ps)
a=-5.8002206*10**3
b=1.3914993
c=-4.8640239*10**-2
d=4.1764768*10**-5
e=-1.4452093*10**-8
f=6.5459673




ps_sup=(np.exp(a/(HP_Air_Supply_Temp+273.15)+b+c*\
           (HP_Air_Supply_Temp+273.15)+d*(HP_Air_Supply_Temp+273.15)**2+\
               e*(HP_Air_Supply_Temp+273.15)**3+f*np.log((HP_Air_Supply_Temp+273.15)))).to_numpy(dtype=float)
    

ps_ret=np.exp(a/(HP_Air_Return_Temp+273.15)+b+c*\
           (HP_Air_Return_Temp+273.15)+d*(HP_Air_Return_Temp+273.15)**2+\
               e*(HP_Air_Return_Temp+273.15)**3+f*np.log((HP_Air_Return_Temp+273.15)))
    
#### Uncertainty Analysis
u_sup=(a/(HP_Air_Supply_Temp+273.15)+b+c*\
           (HP_Air_Supply_Temp+273.15)+d*(HP_Air_Supply_Temp+273.15)**2+\
               e*(HP_Air_Supply_Temp+273.15)**3+f*np.log((HP_Air_Supply_Temp+273.15))).to_numpy(dtype=float)
    
u_ret=(a/(HP_Air_Return_Temp+273.15)+b+c*\
           (HP_Air_Return_Temp+273.15)+d*(HP_Air_Return_Temp+273.15)**2+\
               e*(HP_Air_Return_Temp+273.15)**3+f*np.log((HP_Air_Return_Temp+273.15)))

v_sup=(-a*(HP_Air_Supply_Temp+273.15)**-2+c+2*d*(HP_Air_Supply_Temp+273.15)+3*e*(HP_Air_Supply_Temp+273.15)**2+\
    f/(HP_Air_Supply_Temp+273.15)).to_numpy(dtype=float)

v_ret=-a*(HP_Air_Return_Temp+273.15)**-2+c+2*d*(HP_Air_Return_Temp+273.15)+3*e*(HP_Air_Return_Temp+273.15)**2+\
    f/(HP_Air_Return_Temp+273.15)
    
dps_dT_sup=u_sup*ps_sup*v_sup 
dps_dT_ret=u_ret*ps_ret*v_ret

wps_sup=np.sqrt(dps_dT_sup**2*wTC**2) # Supply Vapor Saturation Pressure Measured Uncertainty
wps_ret=np.sqrt(dps_dT_ret**2*wTC**2) # Return Vapor Saturation Pressure Measured Uncertainty

### Vapor Pressure (pv)
rows=len(HP_Air_Return_Temp)

pv_sup=Supply_RH/100*ps_sup
pv_ret=Return_RH/100*ps_ret

#### Uncertainty Analysis
dpv_dRH_sup=ps_sup
dpv_dps_sup=Supply_RH/100

dpv_dRH_ret=ps_ret
dpv_dps_ret=Return_RH/100

wpv_sup=np.sqrt(dpv_dRH_sup**2*(wRH_sup/100)**2+dpv_dps_sup**2*wps_sup**2)
wpv_ret=np.sqrt(dpv_dRH_ret**2*(wRH_ret/100)**2+dpv_dps_ret**2*wps_ret**2)

### Humidity Ratio
dHR_dpv_sup=0.62198*(1/(Pam-pv_sup)+pv_sup/(Pam-pv_sup)**2)
dHR_dpv_ret=0.62198*(1/(Pam-pv_ret)+pv_ret/(Pam-pv_ret)**2)

wHR_sup=np.sqrt(dHR_dpv_sup**2*wpv_sup**2) # Measured Supply Humidity Ratio Uncertainty (kg/kg)
wHR_ret=np.sqrt(dHR_dpv_ret**2*wpv_ret**2) # Measured Return Humidity Ratio Uncertainty (kg/kg)
wHR_ret_mean=np.mean(wHR_ret)
wHR_ret_std=np.std(wHR_ret)

ZHR_UB=Return_HR+wHR_ret # Upper Measured Bound
ZHR_LB=Return_HR-wHR_ret # Lower Measured Bound

A=0.10903204 # Area of air station (m^2)

rows=len(HP_Air_Return_Temp)
V_a=np.full((rows),fill_value=np.mean(V_a))

v=V_a/A # Air Velocity (m/s)
wv=0.03*v # Air Velocity Uncertainty (m/s)


## Latent Load
dLL_dv=rho_a*A*hfg*(Return_HR-Supply_HR)
dLL_dHR_sup=-rho_a*V_a*hfg
dLL_dHR_ret=rho_a*V_a*hfg

wLL=np.sqrt(dLL_dv**2*wv**2+dLL_dHR_sup**2*wHR_sup**2+dLL_dHR_ret**2*wHR_ret**2) # Measured Latent Load Uncertainty (W)

wLL_mean=np.mean(wLL)
wLL_std=np.std(wLL)

LL_UB=Meas_LL+wLL
LL_LB=Meas_LL-wLL
    
# Plots #######################################################################
## Measured vs Simulated Latent Load 
plt.figure()
plt.xlabel("Time (sec)")
plt.ylabel("Load (W)")
plt.plot(time,Meas_LL, label='Measured')
plt.plot(time,Sim_LL, label='Simulated', color='g')
plt.ylim([-5000,3000])
plt.plot(time,LL_UB, 'r', linewidth=0.1)
plt.plot(time,LL_LB, 'r', linewidth=0.1)
plt.fill_between(time,LL_UB,LL_LB,color='red')
plt.title('Latent Load')
plt.legend(loc='lower right')

# Latent Load Uncertainty
plt.figure()
plt.hist(wLL[i_start:i_end], bins = 100)
plt.xlabel("Uncertainty [W]")
plt.ylabel("# of Samples")
plt.title('Latent Load Uncertainty')








