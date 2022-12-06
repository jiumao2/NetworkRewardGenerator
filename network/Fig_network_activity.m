clear all; close all;

addpath('../lsm/csim')
getParameters;
load('NeuralNetwork_1205.mat');

figure(); hold on;
set(gca, 'Box', 'on', 'XTick', 0:1:3, 'YTick', 0:1:3);

% excitory connections
x_excitory = [];
y_excitory = [];
for k = excitory_neurons
    for j = 1:n_neuron
        if connected(k,j) == 1 && rand()<0.05
            x_excitory = [x_excitory, loc_neuron(k,1), loc_neuron(j,1), NaN];
            y_excitory = [y_excitory, loc_neuron(k,2), loc_neuron(j,2), NaN];
        end
    end
end
plot(x_excitory, y_excitory, '-', 'LineWidth', 0.1, 'Color', [1 .5 .5])

% inhibitory connections
x_inhibitory = [];
y_inhibitory = [];
for k = inhibitory_neurons
    for j = 1:n_neuron
        if connected(k,j) == 1 && rand()<0.05
            x_inhibitory = [x_inhibitory, loc_neuron(k,1), loc_neuron(j,1), NaN];
            y_inhibitory = [y_inhibitory, loc_neuron(k,2), loc_neuron(j,2), NaN];
        end
    end
end
plot(x_inhibitory, y_inhibitory, '-', 'LineWidth', 0.1, 'Color', [.4 .4 1]);

color_i = repmat([0 0 .8], length(inhibitory_neurons), 1);
color_e = repmat([.8 0 0], length(excitory_neurons), 1);
color_i_spike = repmat([0 1 1], length(inhibitory_neurons), 1);
color_e_spike = repmat([1 1 0], length(excitory_neurons), 1);
color_elec = repmat([.2 .2 .2], n_electrode, 1);
color_elec_stim = repmat([.9 .9 .9], n_electrode, 1);

s_i = scatter(loc_neuron(inhibitory_neurons,1),loc_neuron(inhibitory_neurons,2),16,color_i,'filled','square','MarkerEdgeColor','white');
s_e = scatter(loc_neuron(excitory_neurons,1),loc_neuron(excitory_neurons,2),16,color_e,'filled','o','MarkerEdgeColor','white');

% electrode
s_elec = scatter(loc_electrode(:,1),loc_electrode(:,2),72,color_elec,'filled','MarkerEdgeColor','black');

axis square

% %
% for e = 1:n_electrode
%     s_elec.CData(e,:) = color_elec_stim(e,:);
%     fprintf('(%d, %d)\n', row_electrode(e), col_electrode(e));
%     drawnow; pause(.1);
%     s_elec.CData(e,:) = color_elec(e,:);
%     drawnow;
% end
% clc;

%%
spike_timepoint_i = []; spike_id_i = [];
for n = 1:length(inhibitory_neurons)
    spike_timepoint_i = cat(2, spike_timepoint_i, R_neuron.channel(inhibitory_neurons(n)).data);
    spike_id_i = cat(2, spike_id_i, n*ones(1, length(R_neuron.channel(inhibitory_neurons(n)).data)));
end

spike_timepoint_e = []; spike_id_e = [];
for n = 1:length(excitory_neurons)
    spike_timepoint_e = cat(2, spike_timepoint_e, R_neuron.channel(excitory_neurons(n)).data);
    spike_id_e = cat(2, spike_id_e, n*ones(1, length(R_neuron.channel(excitory_neurons(n)).data)));
end

%%
dt = 1e-3;
for r = [6 11]
    for delta_t = -100e-3:dt:100e-3
        t = RBS_timepoint(r)+delta_t;
        stim_on_time = find(abs(t-RBS_timepoint)<=dt, 1);
        if delta_t >= 0 && delta_t <= 20e-3
            stim_electrode = RBS_electrode(stim_on_time);
            s_elec.CData(stim_electrode,:) = color_elec_stim(stim_electrode,:);
%             fprintf('Stimulation: %d/%d on (%d, %d)\n', r, length(RBS_timepoint), col_electrode(stim_electrode), row_electrode(stim_electrode));
        else
            s_elec.CData = color_elec;
        end
    
        spike_i_time = abs(t-spike_timepoint_i)<=dt;
        rest_neuron_i = setdiff(1:length(inhibitory_neurons), spike_id_i(spike_i_time));
        spike_neuron_i = setdiff(1:length(inhibitory_neurons), rest_neuron_i);
        s_i.CData(rest_neuron_i,:) = color_i(rest_neuron_i,:);
        s_i.CData(spike_neuron_i,:) = color_i_spike(spike_neuron_i,:);
    
        spike_e_time = abs(t-spike_timepoint_e)<=dt;
        rest_neuron_e = setdiff(1:length(excitory_neurons), spike_id_e(spike_e_time));
        spike_neuron_e = setdiff(1:length(excitory_neurons), rest_neuron_e);
        s_e.CData(rest_neuron_e,:) = color_e(rest_neuron_e,:);
        s_e.CData(spike_neuron_e,:) = color_e_spike(spike_neuron_e,:);
    
        title_text = sprintf('Stimulation: %d/%d   Time from stimulation: %.0f ms', ceil(r/5), ceil(length(RBS_timepoint)/5), delta_t*1000);
        title(title_text);

        drawnow;
        exportgraphics(gca,'SimulationRBS.gif','Append',true);
        pause(10*dt);
    end
    pause(.5);
end

