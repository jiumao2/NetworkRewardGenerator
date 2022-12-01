clear all; close all;

addpath('../lsm/csim');
addpath('../network');

getParameters;
load('NeuralNetwork.mat');

% use the neural network after 5 hours simulation without external
% stimulation and 2 hours simulation with RBS
csim('destroy');
csim('import', net_with_RBS);

rng(rand_seed)

%% set CPSs
CPS = cell(4, 1);
% manually choose the CPS probe electrodes, to make sure that the animat's traces under different CPS seperate
probe = [8 53 48 5]; % randperm(n_electrode, 4);

for q = 1:4
    CPS{q}.probe = probe(q);
    CPS{q}.first = randperm(n_electrode, 1);
    CPS{q}.second = randperm(n_electrode, 1);
    CPS{q}.interval_1 = min_isi+(max_isi-min_isi)*rand();
    CPS{q}.interval_2 = min_isi+(max_isi-min_isi)*rand();
end

%% pretraining, find CA_mean and T
figure('Units', 'centimeters', 'Position', [2 2 10 10]);
axes('XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-r_outer r_outer], 'YLim', [-r_outer r_outer], 'XTick', [], 'YTick', [], 'LineWidth', 2);
hold on;
viscircles([0 0], r_outer, 'Color', 'k');
viscircles([0 0], r_inner, 'Color', 'k');
axis equal

dot_animat = scatter(0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none');
trace_pre = struct();
for run = 1:5
    for q = 1:4
        title(sprintf('run: %d/5, quadrant: %d', run, q));
        loc_animat = initAnimatLoc(r_inner);
        dist2origin = hypot(loc_animat(1), loc_animat(2));
        trace_animat_pre = loc_animat;
        trace_CA_pre = [];

        dot_animat.MarkerEdgeColor = [0 0 0];
        dot_animat.MarkerFaceColor = color_animat(q,:);
        dot_animat.XData = loc_animat(1);
        dot_animat.YData = loc_animat(2);
        drawnow;

        while dist2origin<=r_outer

            stim_RBS = getRBS(min_isi, max_isi, CPS_interval, stimulator, n_electrode);
            [stim_CPS, time_probe] = getCPS(min_isi, max_isi, CPS, q, stimulator);

            csim('reset');
            csim('simulate', CPS_interval, stim_RBS);

            csim('reset');
            csim('simulate', time_probe+time_after_CPS, stim_CPS);

            firing_rate = zeros(n_electrode, 1);
            for k = 1:n_electrode
                R_after_RBS = csim('get', recorder(k), 'traces');
                for n = 1:n_neuron_recorded_per_electrode
                    firing_rate(k) = firing_rate(k) + sum(R_after_RBS.channel(n).data>time_probe) / time_after_CPS;
                end
            end

            CA = getCA(firing_rate, col_electrode, row_electrode);

            loc_animat = loc_animat + CA;
            dist2origin = hypot(loc_animat(1), loc_animat(2));
            trace_animat_pre = [trace_animat_pre; loc_animat];
            trace_CA_pre = [trace_CA_pre; CA];

            dot_animat.XData = loc_animat(1);
            dot_animat.YData = loc_animat(2);

            plot(trace_animat_pre(end-1:end,1), trace_animat_pre(end-1:end,2), '-', 'Color', [.6 .6 .6], 'LineWidth', 0.2, ...
                'Marker', 'o', 'MarkerFaceColor', color_animat(q,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 2);

            uistack(dot_animat, 'top')

            drawnow;
        end
        trace_pre(run, q).animat = trace_animat_pre;
        trace_pre(run, q).CA = trace_CA_pre;
    end
end
clc;

%% replay the animat's movement - Fig. 1B
figure('Units', 'centimeters', 'Position', [2 2 10 10]);
axes('XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-r_outer r_outer], 'YLim', [-r_outer r_outer], 'XTick', [], 'YTick', [], 'LineWidth', 2);
hold on;
viscircles([0 0], r_outer, 'Color', 'k');
viscircles([0 0], r_inner, 'Color', 'k');
axis equal

dot_animat = scatter(0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none', 'LineWidth', 1);
for run = 1:5
    for q = 1:4
        dot_animat.MarkerEdgeColor = 'black';
        dot_animat.MarkerFaceColor = color_animat(q,:);
        dot_animat.XData = trace_pre(run,q).animat(1,1);
        dot_animat.YData = trace_pre(run,q).animat(1,2);
        drawnow;
        for t = 2:(size(trace_pre(run,q).animat, 1)-1)
            pause(.01);
            plot(trace_pre(run,q).animat(t-1:t,1), trace_pre(run,q).animat(t-1:t,2), '-', 'Color', [.6 .6 .6], 'LineWidth', 0.2, ...
                    'Marker', 'o', 'MarkerFaceColor', color_animat(q,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 2);
            dot_animat.XData = trace_pre(run,q).animat(t,1);
            dot_animat.YData = trace_pre(run,q).animat(t,2);
            uistack(dot_animat, 'top')
            drawnow;
        end
    end
end
dot_animat.MarkerFaceColor = 'none';
dot_animat.MarkerEdgeColor = 'none';
saveas(gca, 'pretraining', 'png');

%%
action_desired = [-1 -1; 1 -1; 1 1; -1 1]; % * sqrt(2)
CA_mean = cell(4,1);
T = cell(4,1);
for q = 1:4
    trace_CA_pre = [];
    for run = 1:5
        trace_CA_pre = [trace_CA_pre; trace_pre(run, q).CA];
    end
    CA_mean{q} = mean(trace_CA_pre);
    T{q} = action_desired(q,:) ./ CA_mean{q};
end
save('BehaviorData', 'CPS', 'CA_mean', 'T', 'trace_pre')

%%
net_after_pretraning = csim('export');
save('../network/NeuralNetwork', ...
    'net_5hours_free', 'net_with_RBS', 'net_after_pretraning', ...
    'loc_neuron', 'loc_electrode', 'col_electrode', 'row_electrode', ...
    'inhibitory_neurons', 'excitory_neurons', 'self_firing_neurons', ...
    'connected', 'synapse', 'neuron', ...
    'stimulator', 'stimulator_synapse', 'recorder', ...
    'RBS_S', 'RBS_R', 'RBS_timepoint', 'RBS_electrode', ...
    'R_neuron');


