% Run a reference 79 kW BMS simulation.
% The model must be in the current folder or on the MATLAB path.

model = 'BMS_CC_CV_79kW';
load_system(model);

t = (0:1:3600)';
packCurrent_A = zeros(size(t));
packCurrent_A(1:1200) = 150;       % charge
packCurrent_A(1801:3000) = -100;   % discharge
ambientTemp_C = 25 * ones(size(t));
chargeRequest = zeros(size(t));
chargeRequest(1:1200) = 1;
dischargeRequest = zeros(size(t));
dischargeRequest(1801:3000) = 1;
cellDeltaSOC_pct = zeros(size(t));
cellDeltaSOC_pct(600:1200) = 3;    % trigger active balancing above 2%

externalInput = [t, packCurrent_A, ambientTemp_C, ...
    chargeRequest, dischargeRequest, cellDeltaSOC_pct];

simOut = sim(model, ...
    'StopTime', '3600', ...
    'LoadExternalInput', 'on', ...
    'ExternalInput', 'externalInput', ...
    'ReturnWorkspaceOutputs', 'on');

signals = simOut.yout;
time = simOut.tout;
packVoltage = signals{1}.Values.Data;
soc = signals{2}.Values.Data;
soh = signals{3}.Values.Data;
soe = signals{4}.Values.Data;
sop = signals{5}.Values.Data;
chargeEnable = signals{6}.Values.Data;
dischargeEnable = signals{7}.Values.Data;
coolingCmd = signals{8}.Values.Data;
heatingCmd = signals{9}.Values.Data;
balanceStatus = signals{10}.Values.Data;

figure('Name', '79 kW BMS reference simulation');
tiledlayout(3, 2);

nexttile;
plot(time, packVoltage);
grid on;
ylabel('V');
title('Pack voltage');

nexttile;
plot(time, soc);
grid on;
ylabel('%');
title('SOC');

nexttile;
plot(time, soh);
grid on;
ylabel('%');
title('SOH');

nexttile;
plot(time, soe);
grid on;
ylabel('%');
title('SOE');

nexttile;
plot(time, sop);
grid on;
ylabel('%');
title('SOP');

nexttile;
stairs(time, [ ...
    chargeEnable, dischargeEnable, coolingCmd, heatingCmd, balanceStatus]);
grid on;
ylim([-0.1, 1.1]);
legend('Charge', 'Discharge', 'Cooling', 'Heating', 'Balance', ...
    'Location', 'eastoutside');
title('BMS commands');
