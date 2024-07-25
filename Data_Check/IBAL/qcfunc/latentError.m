% Examine the results to 
%load('I:/Amanda/DOE Cases/aData/Tucson_Shed_TypShou_RB_2004_TypOcc_TypBehav_NoTES_02152022_101300.mat')

P = HardwareData.scaledData2.indoor_p;
% Inlet to zones
ahu2_out_rtd = HardwareData.scaledData2.ahu2_out_rtd;
ahu2_rh_down = HardwareData.scaledData2.ahu2_rh_down;
w_vav1_out = omega(P,ahu2_out_rtd,ahu2_rh_down);
w_vav2_out = w_vav1_out;
ahu1_out_rtd = HardwareData.scaledData2.ahu1_out_rtd;
ahu1_rh_down = HardwareData.scaledData2.ahu1_rh_down;
w_vav3_out = omega(P,ahu1_out_rtd,ahu1_rh_down);
w_vav4_out = w_vav3_out;
% Outlet from zones
zs1_out_rtd = HardwareData.scaledData2.zs1_out_rtd;
zs1_rh = HardwareData.scaledData2.zs1_rh;
w_zs1_out = omega(P,zs1_out_rtd,zs1_rh);
zs2_out_rtd = HardwareData.scaledData2.zs2_out_rtd;
zs2_rh = HardwareData.scaledData2.zs2_rh;
w_zs2_out = omega(P,zs2_out_rtd,zs2_rh);
zs3_out_rtd = HardwareData.scaledData2.zs3_out_rtd;
zs3_rh = HardwareData.scaledData2.zs3_rh;
w_zs3_out = omega(P,zs3_out_rtd,zs3_rh);
zs4_out_rtd = HardwareData.scaledData2.zs4_out_rtd;
zs4_rh = HardwareData.scaledData2.zs4_rh;
w_zs4_out = omega(P,zs4_out_rtd,zs4_rh);

%w_zs1_out_sim = omega(14.7,(extractfield(SimData,'T_z1_ahu2')-32)*5/9,extractfield(SimData,'RH_z1_ahu2'))';
w_zs1_out_sim = omega(14.7,[SimData.T_z1_ahu2]*9/5+32,[SimData.RH_z1_ahu2])';
w_zs2_out_sim = omega(14.7,[SimData.T_z2_ahu2]*9/5+32,[SimData.RH_z2_ahu2])';
w_zs3_out_sim = omega(14.7,[SimData.T_z1_ahu1]*9/5+32,[SimData.RH_z1_ahu1])';
w_zs4_out_sim = omega(14.7,[SimData.T_z2_ahu1]*9/5+32,[SimData.RH_z2_ahu1])';

% Calculate massflow
[m1,v1] = mDot(HardwareData.scaledData2.vav1_f,ahu2_out_rtd,P,w_vav1_out);
[m2,v2] = mDot(HardwareData.scaledData2.vav2_f,ahu2_out_rtd,P,w_vav2_out);
[m3,v3] = mDot(HardwareData.scaledData2.vav3_f,ahu1_out_rtd,P,w_vav3_out);
[m4,v4] = mDot(HardwareData.scaledData2.vav4_f,ahu1_out_rtd,P,w_vav4_out);

% Calculate q's
q_zs1_sens = sensible(HardwareData.scaledData2.vav1_out_rtd,...
                      HardwareData.scaledData2.zs1_out_rtd,...
                      w_vav1_out,w_zs1_out,m1);
q_zs2_sens = sensible(HardwareData.scaledData2.vav2_out_rtd,...
                      HardwareData.scaledData2.zs2_out_rtd,...
                      w_vav2_out,w_zs2_out,m2);
q_zs3_sens = sensible(HardwareData.scaledData2.vav3_out_rtd,...
                      HardwareData.scaledData2.zs3_out_rtd,...
                      w_vav3_out,w_zs3_out,m3);
q_zs4_sens = sensible(HardwareData.scaledData2.vav4_out_rtd,...
                      HardwareData.scaledData2.zs4_out_rtd,...
                      w_vav4_out,w_zs4_out,m4);
q_zs1_lat = latent(w_vav1_out,w_zs1_out,m1);
q_zs2_lat = latent(w_vav2_out,w_zs2_out,m2);
q_zs3_lat = latent(w_vav3_out,w_zs3_out,m3);
q_zs4_lat = latent(w_vav4_out,w_zs4_out,m4);

zs1_uw_in = uHumRat(ahu2_out_rtd,ahu2_rh_down);
zs2_uw_in = uHumRat(ahu2_out_rtd,ahu2_rh_down);
zs3_uw_in = uHumRat(ahu1_out_rtd,ahu1_rh_down);
zs4_uw_in = uHumRat(ahu1_out_rtd,ahu1_rh_down);

zs1_uw_out = uHumRat(HardwareData.scaledData2.zs1_out_rtd,...
                     HardwareData.scaledData2.zs1_rh);
zs2_uw_out = uHumRat(HardwareData.scaledData2.zs2_out_rtd,...
                     HardwareData.scaledData2.zs2_rh);
zs3_uw_out = uHumRat(HardwareData.scaledData2.zs3_out_rtd,...
                     HardwareData.scaledData2.zs3_rh);
zs4_uw_out = uHumRat(HardwareData.scaledData2.zs4_out_rtd,...
                     HardwareData.scaledData2.zs4_rh);

zs1_uql = uQLatent(HardwareData.scaledData2.vav1_f,...
                   HardwareData.scaledData2.zs1_rh,...
                   HardwareData.scaledData2.zs1_out_rtd,...
                   HardwareData.scaledData2.ahu2_rh_down,...
                   HardwareData.scaledData2.ahu2_out_rtd,...
                   w_zs1_out,w_vav1_out);

zs2_uql = uQLatent(HardwareData.scaledData2.vav2_f,...
                   HardwareData.scaledData2.zs2_rh,...
                   HardwareData.scaledData2.zs2_out_rtd,...
                   HardwareData.scaledData2.ahu2_rh_down,...
                   HardwareData.scaledData2.ahu2_out_rtd,...
                   w_zs2_out,w_vav2_out);
               
zs3_uql = uQLatent(HardwareData.scaledData2.vav3_f,...
                   HardwareData.scaledData2.zs3_rh,...
                   HardwareData.scaledData2.zs3_out_rtd,...
                   HardwareData.scaledData2.ahu1_rh_down,...
                   HardwareData.scaledData2.ahu1_out_rtd,...
                   w_zs3_out,w_vav3_out);
               
zs4_uql = uQLatent(HardwareData.scaledData2.vav4_f,...
                   HardwareData.scaledData2.zs4_rh,...
                   HardwareData.scaledData2.zs4_out_rtd,...
                   HardwareData.scaledData2.ahu2_rh_down,...
                   HardwareData.scaledData2.ahu2_out_rtd,...
                   w_zs4_out,w_vav4_out);
               
% Plot latent loads
figure(1)
xMeas = HardwareData.processData2.comms_timestep;
xSim = [SimData.Timestep];
subplot(2,2,1)
plot(xSim,-[SimData.Qlat_z1_ahu2],xMeas,q_zs1_lat)
title('ZS1')
ylabel('Latent Load [W]')
legend('To Sim','Lab')
xlim([360,1200])
grid on
subplot(2,2,2)
plot(xSim,-[SimData.Qlat_z2_ahu2],xMeas,q_zs2_lat)
title('ZS2')
ylabel('Latent Load [W]')
legend('To Sim','Lab')
xlim([360,1200])
grid on
subplot(2,2,3)
plot(xSim,-[SimData.Qlat_z1_ahu1],xMeas,q_zs3_lat)
title('ZS3')
ylabel('Latent Load [W]')
legend('To Sim','Lab')
xlim([360,1200])
grid on
subplot(2,2,4)
plot(xSim,-[SimData.Qlat_z2_ahu1],xMeas,q_zs4_lat)
title('ZS4')
ylabel('Latent Load [W]')
legend('To Sim','Lab')
xlim([360,1200])
grid on

% Plot humidity ratio
figure(2)
xMeas = HardwareData.processData2.comms_timestep;
xSim = [SimData.Timestep]';
subplot(2,2,1)
p = plot(xSim,w_zs1_out_sim,'k',xMeas,w_zs1_out,...
     xMeas,w_zs1_out+zs1_uw_out,'b',xMeas,w_zs1_out-zs1_uw_out,'b');
p(1).LineWidth = 3;
ylim([0.006,0.011])
title('ZS1')
ylabel('Humidity Ratio [kgw/kgda]')
legend('Sim','Em')
xlim([360,1200])
grid on
subplot(2,2,2)
p = plot(xSim,w_zs2_out_sim,'k',xMeas,w_zs2_out,...
     xMeas,w_zs2_out+zs2_uw_out,'b',xMeas,w_zs2_out-zs2_uw_out,'b');
p(1).LineWidth = 3;
ylim([0.006,0.011])
title('ZS2')
ylabel('Humidity Ratio [kgw/kgda]')
legend('Sim','Em')
xlim([360,1200])
grid on
subplot(2,2,3)
p = plot(xSim,w_zs3_out_sim,'k',xMeas,w_zs3_out,...
     xMeas,w_zs3_out+zs3_uw_out,'b',xMeas,w_zs3_out-zs3_uw_out,'b');
p(1).LineWidth = 3;
ylim([0.006,0.011])
title('ZS3')
ylabel('Humidity Ratio [kgw/kgda]')
legend('Sim','Em')
xlim([360,1200])
grid on
subplot(2,2,4)
p = plot(xSim,w_zs4_out_sim,'k',xMeas,w_zs4_out,...
     xMeas,w_zs4_out+zs4_uw_out,'b',xMeas,w_zs4_out-zs4_uw_out,'b');
p(1).LineWidth = 3;
ylim([0.006,0.011])
title('ZS4')
ylabel('Humidity Ratio [kgw/kgda]')
legend('Sim','Em')
xlim([360,1200])
grid on

% Focus on Zones2 and 3
figure(3)
xMeas = HardwareData.processData2.comms_timestep;
xSim = [SimData.Timestep]';
subplot(2,2,1)
p = plot(xSim,w_zs2_out_sim,'k',xMeas,w_zs2_out,...
     xMeas,w_zs2_out+zs2_uw_out,'b',xMeas,w_zs2_out-zs2_uw_out,'b');
p(1).LineWidth = 3;
ylim([0.006,0.011])
title('ZS2')
ylabel('Humidity Ratio [kgw/kgda]')
legend('Sim','Em')
xlim([360,1200])
grid on
subplot(2,2,2)
p = plot(xSim,w_zs3_out_sim,'k',xMeas,w_zs3_out,...
     xMeas,w_zs3_out+zs3_uw_out,'b',xMeas,w_zs3_out-zs3_uw_out,'b');
p(1).LineWidth = 3;
ylim([0.006,0.011])
title('ZS3')
ylabel('Humidity Ratio [kgw/kgda]')
legend('Sim','Em')
xlim([360,1200])
grid on
subplot(2,2,3)
plot(xMeas,[HardwareData.rawData2.v15_pos_c],[360,1200],[4,4]);
%p(1).LineWidth = 3;
ylim([3,6])
title('V15')
ylabel('Valve Position [V]')
xlim([360,1200])
grid on
subplot(2,2,4)
plot(xMeas,[HardwareData.rawData2.v16_pos_c],[360,1200],[4,4]);
%p(1).LineWidth = 3;
ylim([3,6])
title('V16')
ylabel('Valve Position [V]')
xlim([360,1200])
grid on


figure(4)
xMeas = HardwareData.processData2.comms_timestep;
xSim = [SimData.Timestep];
subplot(2,2,1)
p = plot(xSim,-[SimData.Qlat_z2_ahu2],'k',xMeas,q_zs2_lat,...
         xMeas,q_zs2_lat+zs2_uql,'b',xMeas,q_zs2_lat-zs2_uql,'b');
p(1).LineWidth = 1;
title('ZS2')
ylabel('Latent Load [W]')
legend('Sim','Lab','Error')
xlim([360,1200])
grid on
subplot(2,2,2)
p = plot(xSim,-[SimData.Qlat_z1_ahu1],'k',xMeas,q_zs3_lat,...
         xMeas,q_zs3_lat+zs3_uql,'b',xMeas,q_zs3_lat-zs3_uql,'b');
p(1).LineWidth = 1;
title('ZS3')
ylabel('Latent Load [W]')
legend('Sim','Lab','Error')
xlim([360,1200])
grid on
subplot(2,2,3)
plot(xMeas,[HardwareData.rawData2.v15_pos_c],[360,1200],[4,4]);
%p(1).LineWidth = 3;
ylim([3,6])
title('V15')
ylabel('Valve Position [V]')
xlim([360,1200])
grid on
subplot(2,2,4)
plot(xMeas,[HardwareData.rawData2.v16_pos_c],[360,1200],[4,4]);
%p(1).LineWidth = 3;
ylim([3,6])
title('V16')
ylabel('Valve Position [V]')
xlim([360,1200])
grid on
