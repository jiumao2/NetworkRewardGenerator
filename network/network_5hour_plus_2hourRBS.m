clear all
close all

% tic

addpath('../lsm/csim')
addpath('../task')

getParameters;
Tsim = 100;
csim('destroy')

% set rand_seed
rng(rand_seed)
csim('set','randSeed',rand_seed);
csim('set','dt',dt);
csim('set','nThreads',16);

% Random placing the neurons
loc_neuron = rand(n_neuron,2)*3;
distance_matrix = squareform(pdist(loc_neuron));

% Electrode
loc_electrode = zeros(n_electrode,2);
col_electrode = zeros(n_electrode,1);
row_electrode = zeros(n_electrode,1);

count = 1;
for x = 1:8
    for y = 1:8
        if (x==1 && y==1) || (x==1 && y==8) || (x==8 && y==1) || (x==8 && y==8)
            continue
        else
            loc_electrode(count,1) = x/3;
            loc_electrode(count,2) = y/3;
            col_electrode(count) = x;
            row_electrode(count) = y;
            count = count+1;
        end
    end
end

% set excitory neurons, inhibitory neurons, self-firing neurons and non-self-firing neurons
idx_all = 1:1000;
inhibitory_neurons = randperm(n_neuron,n_neuron*per_inhibitory_neuron);
excitory_neurons = idx_all;
excitory_neurons(inhibitory_neurons) = [];

self_firing_neurons = randperm(n_neuron,n_neuron*per_self_firing_neuron);
non_self_firing_neurons = idx_all;
non_self_firing_neurons(self_firing_neurons) = [];

% create neurons
count_neuron = 0;
neuron = uint32(zeros(n_neuron,1));
for k = 1:n_neuron
    neuron(k) = csim('create','LifNeuron');
    csim('set',neuron(k),'Vthresh',V_thresh);  % threshold
    csim('set',neuron(k),'Trefract',T_refract); % refractory period
    csim('set',neuron(k),'Cm',C_m);        % tau_m = Cm * Rm
    csim('set',neuron(k),'Vreset',V_reset);   % V_reset
    csim('set',neuron(k),'Iinject',0);  % I_back
    csim('set',neuron(k),'Vinit',V_init);    % V_init
    csim('set',neuron(k),'Rm',R_m);
    csim('set',neuron(k),'Vresting',V_resting);

    if any(self_firing_neurons==k)
        csim('set',neuron(k),'Inoise',I_noise_self_firing);
    else
        csim('set',neuron(k),'Inoise',I_noise_non_self_firing);
    end
end

% Connect
connected = zeros(n_neuron);
for k = 1:n_neuron
    dist = distance_matrix(k,:);
    p_connect = exp(-dist)./(sum(exp(-dist))-1);
    idx_neurons = [1:k-1,k+1:n_neuron];
    p_connect = p_connect(idx_neurons);
    for j = 1: max(0,round(randn()*15+50))
        idx_temp = find(cumsum(p_connect)>rand(),1);
        connected(k,idx_neurons(idx_temp)) = 1;
        idx_neurons(idx_temp) = [];
        p_connect(idx_temp) = [];
        p_connect = p_connect./sum(p_connect);
    end
end

count_synapse = 0;
synapse = uint32(zeros(n_synapses*2,1));
for k = 1:n_neuron
    for j = 1:n_neuron
        if connected(k,j)
            count_synapse = count_synapse+1;
            if any(inhibitory_neurons==k)
                synapse(count_synapse) = csim('create','DynamicSpikingSynapse');
                csim('set',synapse(count_synapse),'U',U);
                csim('set',synapse(count_synapse),'D',D);
                csim('set',synapse(count_synapse),'F',F);
                csim('set',synapse(count_synapse),'u0',u0);
                csim('set',synapse(count_synapse),'r0',R0);
                csim('set',synapse(count_synapse),'tau',tau);
                csim('set',synapse(count_synapse),'W',W_init_inhibitory);
                csim('set',synapse(count_synapse),'delay',distance_matrix(k,j)/v_conduction*1e-3);
            else
                synapse(count_synapse) = csim('create','DynamicStdpSynapse');
                csim('set',synapse(count_synapse),'U',U);
                csim('set',synapse(count_synapse),'D',D);
                csim('set',synapse(count_synapse),'F',F);
                csim('set',synapse(count_synapse),'u0',u0);
                csim('set',synapse(count_synapse),'r0',R0);
                csim('set',synapse(count_synapse),'tau',tau);
                csim('set',synapse(count_synapse),'W',W_init_exictory);
                csim('set',synapse(count_synapse),'delay',distance_matrix(k,j)/v_conduction*1e-3);

                csim('set',synapse(count_synapse),'Apos',A_plus);
                csim('set',synapse(count_synapse),'Aneg',A_minus);
                csim('set',synapse(count_synapse),'taupos',tau_plus);
                csim('set',synapse(count_synapse),'tauneg',tau_minus);
                csim('set',synapse(count_synapse),'tauspre',tau_pre);
                csim('set',synapse(count_synapse),'tauspost',tau_post);
                csim('set',synapse(count_synapse),'mupos',mu_plus);
                csim('set',synapse(count_synapse),'muneg',mu_minus);
                csim('set',synapse(count_synapse),'Wex',W_up);
            end
            csim('connect',neuron(j),neuron(k),synapse(count_synapse));
        end
    end
end
synapse(count_synapse+1:end) = [];

%% run without external stimulation for 5 hours in simulated time
fprintf('start simulating without external stimulation for 5 hours...\n');
for t = 1:5*one_hour/one_minute
    csim('simulate', one_minute);
    fprintf('%d/%d minutes\n', t, 5*one_hour/one_minute);
end
clc;
fprintf('finish 5-hour run without external stimulation.\n');

net_5hours_free = csim('export');

csim('reset');

%
W = zeros(length(synapse),1);
for k = 1:length(synapse)
    W(k) = csim('get', synapse(k), 'W');
end
idx_excitory = find(W>0);
W = zeros(length(idx_excitory),1);
for k = 1:length(idx_excitory)
    W(k) = csim('get',synapse(idx_excitory(k)),'W');
end

figure;
xlim([-W_up*0.1,W_up*1.1])
xlabel('Synaptic weights')
ylabel('Number of synapses')

histogram(W, 'BinWidth', 0.001e-6)

%% set electrode-related parameters

% find neuron recorded / stimulated by electrodes
distance_to_electrode = pdist2(loc_electrode, loc_neuron);
[~, distance_to_electrode_sorted] = sort(distance_to_electrode, 2);
neuron_recorded_id = distance_to_electrode_sorted(:, 1:n_neuron_recorded_per_electrode);
neuron_stimulated_id = distance_to_electrode_sorted(:, 1:n_neuron_stimulated_per_electrode);

neuron_recorded = uint32(zeros(n_electrode, n_neuron_recorded_per_electrode));
neuron_stimulated = uint32(zeros(n_electrode, n_neuron_stimulated_per_electrode));
for k = 1:n_electrode
    neuron_recorded(k,:) = neuron(neuron_recorded_id(k,:));
    neuron_stimulated(k,:) = neuron(neuron_stimulated_id(k,:));
end

% set stimulation input neuron and synapse
stimulator = uint32(zeros(n_electrode, 1));
stimulator_synapse = uint32(zeros(n_electrode, n_neuron_stimulated_per_electrode));
for k = 1:n_electrode
    stimulator(k) = csim('create', 'SpikingInputNeuron');
    for n = 1:n_neuron_stimulated_per_electrode
        stimulator_synapse(k,n) = csim('create', 'StaticSpikingSynapse');
        csim('set', stimulator_synapse(k,n), 'W', W_stimulator);
        csim('set', stimulator_synapse(k,n), 'tau', tau);
        csim('connect', neuron_stimulated(k,n), stimulator(k), stimulator_synapse(k,n));
    end
end

% set recorder
recorder = uint32(zeros(n_electrode, 1));
for k = 1:n_electrode
    recorder(k) = csim('create', 'Recorder');
    csim('set', recorder(k), 'dt', dt);
    csim('connect', recorder(k), neuron_recorded(k,:), 'spikes');
end

recorder_neuron = csim('create', 'Recorder');
csim('set', recorder_neuron, 'dt', dt);
csim('connect', recorder_neuron, neuron, 'spikes');

% set RBS stimulation schedule
[RBS_S, RBS_timepoint, RBS_electrode] = getRBS(min_isi, max_isi, 2*one_hour, stimulator, n_electrode);

%% run with random background stimulation (RBS) for another 2 hours
fprintf('\nstart simulating with RBS for another 2 hours...\n');
csim('simulate', 2*one_hour, RBS_S);
clc;
fprintf('finish 2-hour run with RBS.\n');

net_with_RBS = csim('export');

for k = 1:n_electrode
    RBS_R(k) = csim('get', recorder(k), 'traces');
end

R_neuron = csim('get', recorder_neuron, 'traces');

save('NeuralNetwork_1205', ...
    'net_5hours_free', 'net_with_RBS', ...
    'loc_neuron', 'loc_electrode', 'col_electrode', 'row_electrode', ...
    'inhibitory_neurons', 'excitory_neurons', 'self_firing_neurons', ...
    'connected', 'synapse', 'neuron', ...
    'stimulator', 'stimulator_synapse', 'recorder', ...
    'RBS_S', 'RBS_R', 'RBS_timepoint', 'RBS_electrode', ...
    'R_neuron');


