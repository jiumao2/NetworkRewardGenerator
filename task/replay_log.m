% clear
% load('log/log_20221212_114809_withoutPTS.mat')
load('log/log_20221212_113928_PTS.mat')
addpath('../network/')
getParameters;
%%
traj_length = zeros(length(traj),1);
for k = 1:length(traj)
    traj_length(k) = size(traj{k},1);
end
figure;
plot(traj_length,'x')
disp(['mean trajectory length: ',num2str(mean(traj_length))]);
disp(['percentage of exiting from quadrant 1 or 3: ',num2str(sum((log(:,1)==1|log(:,1)==3))./size(log,1))])
%%
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