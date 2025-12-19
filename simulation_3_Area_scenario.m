% --- Simulation Parameters ---

D1 = 0.9;
D2 = 1.5;
D3 = 1.3;
Tg1 = 0.23;
Tch1 = 0.39;
Tg2 = 0.14;
Tch2 = 0.5;
Trh = 7;
Fhp = 0.4;
Tg3 = 0.4;
Tw = 2.25;
Tr = 5;
Rt = 0.38;
Rp = 0.05;
R1 = 0.1;
R3 = 0.1;
R2 = 0.1;
R4 = 0.1;
R5 = 0.1;
R6 = 0.1;
R7 = 0.1;
KI1 = 0.25;
KI2 = 0.25;
KI3 = 0.25;
KI4 = 0.25;
KI5 = 0.25;
KI6 = 0.25;
KI7 = 0.25;
T12 = 2;
T13 = 2;
T23 = 2;
a12 = -1;
a13 = -1;
a23 = -1;
Tg4 = 0.3;
Tch4 = 0.45; 

% Single reheat steam turbine of area 3 
Tg5 = 0.1;
Tch5 = 0.4;
Trh_3 = 5;
Fhp_3 = 0.35;


% Gas Turbine Params
b = 0.05;
c = 1;
X = 0.6;
Y = 1;
Tf = 0.23;
Tcr = 0.01;
Tcd = 0.2;

% Biomass Params
Tg6 = 0.08;
Tch6 = 0.3;
Trh2 = 10;
Fhp2 = 0.3;

% Calculate equivalent resistances and B coefficients
Rtotal_1 = (1/R1 + 1/R2)^(-1);
Rtotal_2 = (1/R3 + 1/R4)^(-1);
Rtotal_3 = (1/R5 + 1/R6 + 1/R7)^(-1);
B1 = (1/Rtotal_1) + D1;
B2 = (1/Rtotal_2) + D2;
B3 = (1/Rtotal_3) + D3;




% === Simulation Configuration ===
num_samples     = 1000;
sample_interval = 0.01;
duration        = 90;
t_sample        = 0:sample_interval:duration;
sequence_length = length(t_sample);  % 9001
H_range         = [3, 8];
model_name      = 'mark_6';  % Your Simulink model

% === Preallocate Data ===
all_data    = zeros(num_samples, sequence_length, 6);  % df1, df2, df3, ptie1, ptie2, ptie3
all_targets = zeros(num_samples, 3);                   % H1, H2, H3

% === Generate Random Inertia Values ===
H1_values = H_range(1) + (H_range(2) - H_range(1)) * rand(num_samples, 1);
H2_values = H_range(1) + (H_range(2) - H_range(1)) * rand(num_samples, 1);
H3_values = H_range(1) + (H_range(2) - H_range(1)) * rand(num_samples, 1);

% === Progress Bar ===
h = waitbar(0, 'Running simulations...');

for i = 1:num_samples
    H1 = H1_values(i);
    H2 = H2_values(i);
    H3 = H3_values(i);

    % assignin('base', 'H1', H1);
    % assignin('base', 'H2', H2);
    % assignin('base', 'H3', H3);

    % === Disturbance Generation ===
    rng(1000 + i);

    fs = 100;
    t = linspace(0, duration, fs * duration + 1);

    % Disturbance 1: low freq
    noise_amp1 = 0.25e-3 + 0.1e-3 * rand();
    sine_amp1 = 0.1e-3 + 0.1e-3 * rand();
    sine_freq1 = 0.4 + 0.3 * rand();
    disturbance1 = noise_amp1 * randn(size(t)) + sine_amp1 * sin(2*pi*sine_freq1*t);

    % Disturbance 2: high freq
    noise_amp2 = 0.3e-3 + 0.15e-3 * rand();
    sine_amp2 = 0.15e-3 + 0.15e-3 * rand();
    sine_freq2 = 3 + 3 * rand();
    disturbance2 = noise_amp2 * randn(size(t)) + sine_amp2 * sin(2*pi*sine_freq2*t);

    % Disturbance 3: mid freq
    noise_amp3 = 0.2e-3 + 0.1e-3 * rand();
    sine_amp3 = 0.2e-3 + 0.05e-3 * rand();
    sine_freq3 = 1 + 1 * rand();
    disturbance3 = noise_amp3 * randn(size(t)) + sine_amp3 * sin(2*pi*sine_freq3*t);

    % assignin('base', 'disturbance1', disturbance1);
    % assignin('base', 'disturbance2', disturbance2);
    % assignin('base', 'disturbance3', disturbance3);
    % assignin('base', 't_dist', t);

    % === Simulate ===
    simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');

    % === Extract Outputs ===
    df1   = simOut.get('df1').signals.values;
    df2   = simOut.get('df2').signals.values;
    df3   = simOut.get('df3').signals.values;
    ptie1 = simOut.get('ptie1').signals.values;
    ptie2 = simOut.get('ptie2').signals.values;
    ptie3 = simOut.get('ptie3').signals.values;

    % === Store Outputs ===
    all_data(i, :, 1) = df1;
    all_data(i, :, 2) = df2;
    all_data(i, :, 3) = df3;
    all_data(i, :, 4) = ptie1;
    all_data(i, :, 5) = ptie2;
    all_data(i, :, 6) = ptie3;

    all_targets(i, :) = [H1, H2, H3];

    waitbar(i / num_samples, h, sprintf("Simulation %d of %d", i, num_samples));
end

close(h);

% === Save ===
save('simulink_dataset_3area_multisource_3_sources.mat', 'all_data', 'all_targets', '-v7.3');
fprintf("✅ simulink_dataset_3area_multisource_3_sources.mat\n");


