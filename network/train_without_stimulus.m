clear all
close all

addpath('../lsm/csim')
getParameters;
Tsim = 3600;
rand_seed = 1;

csim('destroy')

% set rand_seed
rng(rand_seed)
csim('set','randSeed',rand_seed);
csim('set','dt',dt);

% Random placing the neurons
loc_neuron = rand(n_neuron,2)*3;
distance_matrix = squareform(pdist(loc_neuron));

% Electrode
loc_electrode = zeros(n_electrode,2);
neurons_recored_electrode = zeros(n_electrode,n_neuron_recorded_per_electrode);
neurons_stimulated_electrode = zeros(n_electrode,n_neuron_stimulated_per_electrode);

count = 1;
for x = 1:8
    for y = 1:8
        if (x==1 && y==1) || (x==1 && y==8) || (x==8 && y==1) || (x==8 && y==8)
            continue
        else
            loc_electrode(count,1) = x/3;
            loc_electrode(count,2) = y/3;
            
            dist_electrode_neuron = sum((loc_neuron-loc_electrode(count,:)).^2,2);
            [~, idx_sort] = sort(dist_electrode_neuron,'ascend');
            neurons_recored_electrode(count,:) = idx_sort(1:n_neuron_recorded_per_electrode);
            neurons_stimulated_electrode(count,:) = idx_sort(1:n_neuron_stimulated_per_electrode);
            
            count = count+1;
        end
    end
end

%% set excitory neurons, inhibitory neurons, self-firing neurons and non-self-firing neurons
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

% set recorder
rec_spikes = uint32(zeros(n_neuron,1));
for k = 1:n_neuron
    rec_spikes(k) = csim('create','MexRecorder');
    csim('set',rec_spikes(k),'dt',dt);
    csim('connect',rec_spikes(k), neuron(k), 'spikes');
end

% simulate
for k = 1:round(Tsim/60)
    tic
    csim('simulate', 60);
    toc
end

t_total = Tsim;

net = csim('export');
save(['Net_seed_',num2str(rand_seed),'_',num2str(t_total)],...
    'net',...
    'neuron',...
    'synapse',...
    'rec_spikes',...
    'loc_electrode',...
    'loc_neuron',...
    'distance_matrix',...
    'neurons_recored_electrode',...
    'neurons_stimulated_electrode',...
    'connected',...
    'excitory_neurons',...
    'inhibitory_neurons',...
    'self_firing_neurons',...
    'non_self_firing_neurons',...
    't_total')

    