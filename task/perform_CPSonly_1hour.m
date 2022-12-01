%% CPS only

% use the neural network after 5 hours simulation without external
% stimulation and 2 hours simulation with RBS and pretraining
csim('destroy');
csim('import', net_after_pretraning);

rng(rand_seed)

%% perform task for one hour under CPS only
figure('Units', 'centimeters', 'Position', [2 2 10 10], 'Renderer', 'opengl');
axes('XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-50 50], 'YLim', [-50 50], 'XTick', [], 'YTick', [], 'LineWidth', 2);
hold on;
viscircles([0 0], 50, 'Color', 'k');
viscircles([0 0], 5, 'Color', 'k');
axis equal

%
dot_animat = scatter(0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none', 'LineWidth', 1);
trace_CPSonly_1hour = struct();

loc_animat = initAnimatLoc(r_inner);
quadrant = getQuadrant(loc_animat);
dist_to_origin = hypot(loc_animat(1), loc_animat(2));
trace_CPSonly_1hour.animat = loc_animat;
trace_CPSonly_1hour.movement = [];
trace_CPSonly_1hour.distance = dist_to_origin;
trace_CPSonly_1hour.time = 0;

scatter(loc_animat(1), loc_animat(2), 2, color_animat(quadrant,:), 'filled', 'MarkerEdgeColor', 'none');

dot_animat.MarkerEdgeColor = [0 0 0];
dot_animat.MarkerFaceColor = [0 0 1];
dot_animat.XData = loc_animat(1);
dot_animat.YData = loc_animat(2);
uistack(dot_animat, 'top');
drawnow;

t = 0;
while 1

    if t > one_hour
        dot_animat.MarkerEdgeColor = 'none';
        dot_animat.MarkerFaceColor = 'none';
        drawnow;
        break;
    end
    if dist_to_origin > r_outer
        loc_animat = initAnimatLoc(r_inner);
        quadrant = getQuadrant(loc_animat);
        dist_to_origin = hypot(loc_animat(1), loc_animat(2));
        trace_CPSonly_1hour.animat = [trace_CPSonly_1hour.animat; loc_animat];
        trace_CPSonly_1hour.movement = [trace_CPSonly_1hour.movement; [nan nan]];
        trace_CPSonly_1hour.distance = [trace_CPSonly_1hour.distance; dist_to_origin];
        trace_CPSonly_1hour.time = [trace_CPSonly_1hour.time; t];
    end

    [stim_CPS, time_probe] = getCPS(min_isi, max_isi, CPS, quadrant, stimulator);

    csim('reset');
    csim('simulate', CPS_interval);
    t = t + csim('get', 't');

    csim('reset');
    csim('simulate', time_probe+time_after_CPS, stim_CPS);
    t = t + csim('get', 't');

    firing_rate = zeros(n_electrode, 1);
    for k = 1:n_electrode
        R_after_CPS = csim('get', recorder(k), 'traces');
        for n = 1:n_neuron_recorded_per_electrode
            firing_rate(k) = firing_rate(k) + sum(R_after_CPS.channel(n).data>time_probe) / time_after_CPS;
        end
    end

    CA = getCA(firing_rate, col_electrode, row_electrode);

    loc_animat = loc_animat + T{quadrant} .* CA;
    quadrant = getQuadrant(loc_animat);
    dist_to_origin = hypot(loc_animat(1), loc_animat(2));
    trace_CPSonly_1hour.animat = [trace_CPSonly_1hour.animat; loc_animat];
    trace_CPSonly_1hour.movement = [trace_CPSonly_1hour.movement; T{quadrant}.*CA];
    trace_CPSonly_1hour.distance = [trace_CPSonly_1hour.distance; dist_to_origin];
    trace_CPSonly_1hour.time = [trace_CPSonly_1hour.time; t];

    dot_animat.XData = loc_animat(1);
    dot_animat.YData = loc_animat(2);

    plot(trace_CPSonly_1hour.animat(end-1:end,1), trace_CPSonly_1hour.animat(end-1:end,2), '-', 'Color', [.6 .6 .6], 'LineWidth', 0.2)
    scatter(loc_animat(1), loc_animat(2), 2, color_animat(quadrant,:), 'filled')
    uistack(dot_animat, 'top');
    title(sprintf('%.2f min', t/one_minute));
    drawnow;
end
clc;

dot_animat.MarkerFaceColor = 'none';
dot_animat.MarkerEdgeColor = 'none';
saveas(gca, 'movement_CPSonly_1hour', 'png');



