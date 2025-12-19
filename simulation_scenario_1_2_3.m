% --- Simulation Parameters ---
%MARK 4 (scenario 2) parameters
% D1 = 0.9;
% D2 = 1.5;
% Tg1 = 0.23;
% Tch1 = 0.39;
% Tg2 = 0.14;
% Tch2 = 0.5;
% Trh = 7;
% Fhp = 0.4;
% Tg3 = 0.4;
% Tw = 2.25;
% Tr = 5;
% Rt = 0.38;
% Rp = 0.05;
% R1 = 0.25;
% R2 = 0.25;
% R3 = 0.05;
% R4 = 0.05;
% KI1 = 0.25;
% KI2 = 0.25;
% KI3 = 0.25;
% KI4 = 0.25;
% T12 = 2;
% a12  = -1;
% Tg4 = 0.5; 
% B1 = 8.9;
% B2 = 41.5;


%paraneters for mark 5 (scenario 3):2X{hydro+reheat steam turbine}


% D1 = 0.9;
% D2 = 1.5;
% Tg1 = 0.45;
% Tg2 = 0.14;
% Tch2 = 0.5;
% Trh = 7;
% Fhp = 0.4;
% Tg3 = 0.4;
% Tw = 2.25;
% Tr = 5;
% Rt = 0.38;
% Rp = 0.05;
% R1 = 0.25;
% R3 = 0.25;
% R4 = 0.05;
% R2 = 0.05;
% KI1 = 0.25;
% KI2 = 0.25;
% KI4 = 0.25;
% KI3 = 0.25;
% KI4 = 0.25;
% T12 = 2;
% a12  = -1;
% Tg4 = 0.16;
% Tch4 = 0.55; 
% B1 = 24.9;
% B2 = 25.5;


%pamams for the original model mark3 (scenario 1)
D1 = 0.9;
D2 = 1.5;
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
R1 = 0.05;
R3 = 0.05;
R2 = 0.05;
R4 = 0.05;
KI1 = 0.25;
KI2 = 0.25;
KI3 = 0.25;
KI4 = 0.25;
T12 = 2;
a12  = -1;
Tg4 = 0.3;
Tch4 = 0.45; 
B1 = 40.9;
B2 = 41.5;



% === Configuration ===
num_samples     = 1000;        % Number of H1, H2 pairs
sample_interval = 0.01;        % Sampling step size (ensure Simulink is fixed-step)
duration        = 90;          % Duration in seconds
t_sample        = 0:sample_interval:duration;
sequence_length = length(t_sample);  % 9001
H_range         = [3, 8];      % Range for H1 and H2
model_name      = 'mark_3';    % <--- Replace with your Simulink model name

% === Preallocate Data Arrays ===
all_data    = zeros(num_samples, sequence_length, 3);  % Δf1, Δf2, ΔPtie
all_targets = zeros(num_samples, 2);                   % H1, H2

% === Generate Random H1, H2 Values ===
H1_values = H_range(1) + (H_range(2) - H_range(1)) * rand(num_samples, 1);
H2_values = H_range(1) + (H_range(2) - H_range(1)) * rand(num_samples, 1);

% === Progress Bar ===
h = waitbar(0, 'Running simulations...');

for i = 1:num_samples
    H1 = H1_values(i);
    H2 = H2_values(i);

    % === Generate unique disturbances for this simulation ===
    rng(1000 + i);  % Seed depends on i for reproducibility and uniqueness

    % Parameters
    fs = 100;
    duration = 90;
    t = linspace(0, duration, fs * duration+1);

    % Disturbance 1: Noise + low freq sine (random amplitude and freq variation)
    noise_amp1 = 0.25e-3 + 0.1e-3 * rand();
    sine_amp1 = 0.1e-3 + 0.1e-3 * rand();
    sine_freq1 = 0.4 + 0.3 * rand();
    disturbance1 = noise_amp1 * randn(size(t)) + sine_amp1 * sin(2*pi*sine_freq1*t);

    % Disturbance 2: Noise + high freq sine (random amplitude and freq variation)
    noise_amp2 = 0.3e-3 + 0.15e-3 * rand();
    sine_amp2 = 0.15e-3 + 0.15e-3 * rand();
    sine_freq2 = 3 + 3 * rand();
    disturbance2 = noise_amp2 * randn(size(t)) + sine_amp2 * sin(2*pi*sine_freq2*t);

    % --- Run the simulation with these disturbances ---
    simOut = sim(model_name, 'ReturnWorkspaceOutputs', 'on');

    % Extract signals
    df1  = simOut.get('df1').signals.values;
    df2  = simOut.get('df2').signals.values;
    ptie = simOut.get('ptie').signals.values;

    % % Store the disturbance signals in the data array
    % all_data(i, :, 4) = disturbance1;  % Store disturbance 1
    % all_data(i, :, 5) = disturbance2;  % Store disturbance 2

    % Store system responses
    all_data(i, :, 1) = df1;
    all_data(i, :, 2) = df2;
    all_data(i, :, 3) = ptie;

    % Store H1 and H2 values
    all_targets(i, :) = [H1, H2];

    waitbar(i / num_samples, h, sprintf("Simulation %d of %d", i, num_samples));
end

close(h);

% === Save the dataset with disturbances ===
save('simulink_dataset_different_disturbances_multiple_sources_probe_signal.mat', 'all_data', 'all_targets', '-v7.3');
fprintf("✅ Saved dataset with disturbances: simulink_dataset_different_disturbances_multiple_sources_probe_signal.mat\n");

% %if you need to save it for scenario 2 uncomment this
% 
% % === Save the dataset with disturbances ===
% save('simulink_dataset_different_disturbances_2_hydro_sources_probe_signal.mat', 'all_data', 'all_targets', '-v7.3');
% fprintf("✅ Saved dataset with disturbances: simulink_dataset_different_disturbances_2_hydro_sources_probe_signal.mat'\n");

% 
% %if you need to save it for scenario 3 uncomment this
% 
% % === Save the dataset with disturbances ===
% save('simulink_dataset_different_disturbances_2x{hydro+steam}_sources_probe_signal.mat', 'all_data', 'all_targets', '-v7.3');
% fprintf("✅ Saved dataset with disturbances: simulink_dataset_different_disturbances_2x{hydro+steam}_sources_probe_signal.mat'\n");
