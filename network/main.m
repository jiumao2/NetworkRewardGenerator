getParameters;

% set rand_seed
rng(rand_seed)

% Random placing the neurons
loc_neuron = rand(n_neuron,1)*2;
distance_matrix = squareform(pdist(loc_neuron));

% Electrode
loc_electrode = zeros(n_electrode,2);

count = 1;
for x = 1:8
    for y = 1:8
        if (x==1 && y==1) || (x==1 && y==8) || (x==8 && y==1) || (x==8 && y==8)
            continue
        else
            loc_electrode(count,1) = x/3;
            loc_electrode(count,2) = y/3;
            count = count+1;
        end
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

% set excitory neurons, inhibitory neurons, self-firing neurons and non-self-firing neurons
idx_all = 1:1000;
inhibitory_neurons = randperm(n_neuron,n_neuron*per_inhibitory_neuron);
excitory_neurons = idx_all;
excitory_neurons(inhibitory_neurons) = [];

self_firing_neurons = randperm(n_neuron,n_neuron*per_self_firing_neuron);
non_self_firing_neurons = idx_all;
non_self_firing_neurons(self_firing_neurons) = [];

% initialize weights
W = zeros(n_neuron);
W(inhibitory_neurons,:) = W_init_inhibitory; % fixed
W(excitory_neurons,:) = W_init_exictory; % STDP
W(connected==0) = 0;

% initialize V_m
V_m = V_resting*ones(n_neuron,1);
refract_steps = zeros(n_neuron,1);
I_syn = zeros(n_neuron,1);

% initialize STDP
dt_pre = zeros(n_neuron);
dt_post = zeros(n_neuron,1);
spike_time_post = -1e8*ones(n_neuron,1);
e_pre = ones(n_neuron,1);
e_post = ones(n_neuron,1);


% updating V_m
u = zeros(n_neuron);
R = zeros(n_neuron);

t = 0:dt:Tsim;
spike_time_last = -1e8*ones(n_neuron);
spike_time_arriving = -1e8*ones(n_neuron);

figure;
for k = 2:length(t)
    I_syn = zeros(n_neuron,1);
    
    I_noise = zeros(n_neuron,1);
    I_noise(non_self_firing_neurons) = I_noise_non_self_firing*randn(length(non_self_firing_neurons),1);
    I_noise(self_firing_neurons) = I_noise_self_firing*randn(length(self_firing_neurons),1);
    for i = 1:n_neuron
        for j = idx_all(connected(:,i)==1)
            if abs(t(k)-spike_time_arriving(j,i))<1e-6
                % Frequency-dependent dynamics
                dt_pre(j,i) = t(k)-spike_time_last(j,i);
                if spike_time_last(j,i) < 0
                    u(j,i) = u0 + U*(1-u0);
                    R(j,i) = 1-U;
                else
                    u(j,i) = u(j,i)*exp(-(t(k)-spike_time_last(j,i))/tau)+U*(1-u(j,i)*exp(-(t(k)-spike_time_last(j,i))/tau));
                    R(j,i) = R(j,i)*(1-u(j,i))*exp(-(t(k)-spike_time_last(j,i))/D)+1-exp(-(t(k)-spike_time_last(j,i))/D);   
                end
                spike_time_last(j,i) = t(k);
                I_syn(i) = I_syn(i) + W(j,i)*R(j,i)*u(j,i);
                
                % STDP
                if any(excitory_neurons==j)
                    dw = (W(j,i)-W_low).^mu_low*A_minus*exp(-(t(k)-spike_time_post(i))/tau_minus);
                    e_pre(i) = 1-exp(-dt_pre(j,i)/tau_pre);
                    W(j,i) = W(j,i)*(1+e_pre(i)*e_post(i)*(-dw));
                end
            else
                if spike_time_last(j,i) ~= 0
                    I_syn(i) = I_syn(i)+W(j,i)*exp(-(t(k)-spike_time_last(j,i))/tau)*R(j,i)*u(j,i);
                end
            end
        end
    
        if refract_steps(i) > 0
            V_m(i) = V_reset;
            refract_steps(i) = refract_steps(i)-1;
            continue
        end

        dvm_dt = @(V_m)1/tau_m*(-(V_m-V_resting)+R_m*(I_syn(i)*(V_thresh-V_resting)/R_m*10 + I_noise(i)));
        V_m(i) = rungekutta(dvm_dt,dt,V_m(i));
        if V_m(i) > V_thresh
            V_m(i) = 0;
            refract_steps(i) = round(T_refract/dt);
            for i_neuron = idx_all(connected(i,:)==1)
                spike_time_arriving(i,i_neuron) = t(k) + dt*round(distance_matrix(i,i_neuron)/v_conduction/dt);
            end
            % STDP
            dt_post(i) = t(k) - spike_time_post(i);
            spike_time_post(i) = t(k);
            for j = idx_all(connected(:,i)==1)
                if any(excitory_neurons == j)
                    dw = (W_up-W(j,i)).^mu_plus*A_plus*exp(-(t(k)-spike_time_last(j,i))/tau_plus);
                    e_post(i) = 1-exp(-dt_post(i)/tau_post);
                    W(j,i) = W(j,i)*(1+e_pre(i)*e_post(i)*dw);
                end
            end           
        end
    end
    
    clf;
    W_temp = W(excitory_neurons,:);
    connected_temp = connected(excitory_neurons,:);
    histogram(W_temp(connected_temp==1), 'BinWidth', 0.001)
%     xlim([0,0.1])
    xlabel('Synaptic weights')
    ylabel('Number of synapses')
    title(['t = ',num2str(t(k)/1000) ,'s'])
    drawnow;
    
end



















