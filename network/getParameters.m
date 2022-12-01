rand_seed = 1;
Tsim = 100;
one_hour = 3600;
one_minute = 60;

dt = 0.1*1e-3; % s
dt_spikes = 0.1*1e-3;
dt_W = 100*1e-3;
n_neuron = 1000;
n_synapses = 50000;
per_inhibitory_neuron = 0.3;
per_self_firing_neuron = 0.3;

v_conduction = 0.3; % mm/ms
a_area = 3; % mm

V_resting = -0.070; % V
V_init = -0.070;
V_thresh = -0.054;
V_reset = -0.060;
T_refract = 0.003; % s
C_m = 3e-8; % F
R_m = 1e6; % ohm
tau_m = 0.030; % s
I_noise_self_firing = 105e-9; % nA
I_noise_non_self_firing = 75e-9; % nA

% for excitory and inhibitory neurons: frequency dependent
R0 = 1;
U = 0.5;
u0 = 0.5;
D = 0.8; % s
F = 1; % s
tau = 0.003; % s

% for excitory neurons: STDP
A_plus = 0.5;
A_minus = -0.5*1.05;
tau_plus = 0.020; % s
tau_minus = 0.020;
W_conductance = 406e-9;
W_init_exictory = 0.5*W_conductance;
W_init_inhibitory = -0.5*W_conductance;
W_up = 1*W_conductance;
W_low = 0*W_conductance;
mu_plus = 1;
mu_minus = 1;
tau_pre = 0.034;
tau_post = 0.075;

% Electrode
n_electrode = 60;
n_neuron_recorded_per_electrode = 5;
n_neuron_stimulated_per_electrode = 76;
W_stimulator = 0.7*W_conductance;

stimulus_amplitude = 20e-9;
t_recording = 0.1;

% for task
min_isi = 200e-3;
max_isi = 400e-3; % inter-stimulation interval: 200-400ms
CPS_interval = 5; % inter-CPS interval: 5s
time_after_CPS = 100e-3; % use firing rate at recording electrodes within 100ms after CPS probe
r_outer = 50;
r_inner = 5;
color_animat = [1 0 0; 0 1 0; .5 .5 .5; 0 0 1];






