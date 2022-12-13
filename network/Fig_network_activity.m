clear all; close all;

addpath('../lsm/csim')
getParameters;
load('NeuralNetwork_1210.mat');

figure(); hold on;
set(gcf, 'Name', 'Network', 'Units', 'centimeters', 'Position', [3 3 15 15], ...
    'PaperPositionMode', 'auto', 'color', 'w', 'renderer', 'opengl', 'toolbar', 'none', 'resize', 'off');
set(gca, 'Box', 'on', 'XTick', 0:1:3, 'YTick', 0:1:3, 'FontSize', 12);

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

RBS_timepoint = []; RBS_electrode = [];
for e = 1:60
    stim_time = find(RBS_S(e).data>0);
    if ~isempty(stim_time)
        stim_lap = [0 diff(stim_time)];
        RBS_timepoint = [RBS_timepoint stim_time(stim_lap~=1)*1e-4];
        RBS_electrode = [RBS_electrode e*ones(1,sum(stim_lap~=1))];
    end
end
[RBS_timepoint, sort_id] = sort(RBS_timepoint);
RBS_electrode = RBS_electrode(sort_id);
%%
F = struct('cdata', [], 'colormap', []); k = 0;
dt = 1e-3;
for r = 5:10
    for delta_t = -25e-3:dt:50e-3
        k = k+1;
        t = RBS_timepoint(r)+delta_t;
        stim_on_time = find(abs(t-RBS_timepoint)<=dt, 1);
        if delta_t == 0
            stim_electrode = RBS_electrode(stim_on_time);
            s_elec.CData(stim_electrode,:) = color_elec_stim(stim_electrode,:);
        else
            s_elec.CData = color_elec;
        end
    
        spike_i_time = t-spike_timepoint_i<=dt & t-spike_timepoint_i>0;
        rest_neuron_i = setdiff(1:length(inhibitory_neurons), spike_id_i(spike_i_time));
        spike_neuron_i = setdiff(1:length(inhibitory_neurons), rest_neuron_i);
        s_i.CData(rest_neuron_i,:) = color_i(rest_neuron_i,:);
        s_i.CData(spike_neuron_i,:) = color_i_spike(spike_neuron_i,:);
    
        spike_e_time = spike_timepoint_e>=t & spike_timepoint_e<t+dt;
        rest_neuron_e = setdiff(1:length(excitory_neurons), spike_id_e(spike_e_time));
        spike_neuron_e = setdiff(1:length(excitory_neurons), rest_neuron_e);
        s_e.CData(rest_neuron_e,:) = color_e(rest_neuron_e,:);
        s_e.CData(spike_neuron_e,:) = color_e_spike(spike_neuron_e,:);
    
        title_text = sprintf('Time from stimulation onset: %.0f ms', delta_t*1000);
        title(title_text);

        drawnow;
        F(k) = getframe(gcf);
    end
end

%%
writerObj = VideoWriter('Network_stimulation.avi');
writerObj.FrameRate = 10;
open(writerObj);

for ifrm=1:length(F)
    frame = F(ifrm);
    writeVideo(writerObj, frame);
end
close(writerObj);
