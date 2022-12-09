clear
load('log_20221209_180431.mat')
addpath('../network/')
getParameters;

fig = figure('Visible','on', 'Units', 'centimeters', 'Position', [2 2 10 10], 'Renderer', 'opengl');
ax = axes(fig,'XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-50 50], 'YLim', [-50 50], 'XTick', [], 'YTick', [], 'LineWidth', 2, 'NextPlot', 'add');
viscircles(ax, [0 0], r_outer, 'Color', 'k');
viscircles(ax, [0 0], r_inner, 'Color', 'k');
axis(ax, 'equal');
dot_animat = scatter(ax, 0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none', 'LineWidth', 1);
time = 0
for k = 1:length(traj)
    cla(ax);
    dot_animat = scatter(ax, 0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none', 'LineWidth', 1);
    viscircles(ax, [0 0], r_outer, 'Color', 'k');
    viscircles(ax, [0 0], r_inner, 'Color', 'k');
    
    location_last = [0,0];
    for j = 1:size(traj{k},1)
        time = time+0.1;
        
        location = [traj{k}(j,1), traj{k}(j,2)];
        scatter(ax,location(1), location(2), 2, color_animat(getQuadrant(location),:), 'filled');
        plot(ax,[location_last(1),location(1)], ...
            [location_last(2),location(2)], '-', 'Color', [.6 .6 .6], 'LineWidth', 0.2);
        location_last = location;
        dot_animat.MarkerEdgeColor = [0 0 0];
        dot_animat.MarkerFaceColor = [0 0 1];
        dot_animat.XData = location(1);
        dot_animat.YData = location(2);
        uistack(dot_animat, 'top');
        title(ax,sprintf('trial %d; time: %.1f min', k, time));
        drawnow;
    end
end