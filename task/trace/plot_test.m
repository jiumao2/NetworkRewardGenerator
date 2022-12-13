clear; close all

stimulation_mode = {'short', 'long'};
training_program = {'greedy', 'paper', 'without_PTS'};
for stimulation_mode_chosen = 1:2
    Distance = cell(1,3); Time = cell(1,3);
for training_program_chosen = 1:3

data_file = dir(['*' stimulation_mode{stimulation_mode_chosen} '*' training_program{training_program_chosen} '*.mat']);
load(data_file.name)

%%
trace.movement = diff(trace.traj);

trace.quadrant(trace.quadrant==1 & trace.time>600) = 13;
trace.quadrant(trace.quadrant==3 & trace.time>600) = 31;
trace.quadrant(trace.quadrant==13) = 3;
trace.quadrant(trace.quadrant==31) = 1;
trace.quadrant_2 = trace.quadrant(1:end-1);

Distance = hypot(trace.traj(:,1), trace.traj(:,2));
%%
C = colororder;

%% CA plot
q_plot = [0.45 0.55 0.32 0.4;
    0.08 0.55 0.32 0.4;
    0.08 0.1 0.32 0.4;
    0.45 0.1 0.32 0.4;];
figure('Units', 'centimeters', 'Position', [5 5 15 12]);
colormap('parula');
ax = zeros(1,4);
for q = 1:4
    ax(q) = axes(gcf, 'Position', q_plot(q,:), 'FontSize', 9, 'Box', 'on', ...
        'XTick', -2:1:2, 'YTick', -2:1:2, 'XLim', [-2 2], 'YLim', [-2 2], 'LineWidth', 1.5); hold on;
    action_this = trace.action(trace.quadrant_2==q);
    action_max = mode(action_this);
    plot([0 0], [-2 2], ':k', 'LineWidth', 1);
    plot([-2 2], [0 0], ':k', 'LineWidth', 1);
    scatter(trace.CA(trace.quadrant_2==q,1), trace.CA(trace.quadrant_2==q,2), 12, trace.time(trace.quadrant_2==q)/60, ...
        'filled', 'MarkerFaceAlpha', 0.7);
    if q==1 || q==2
        xticklabels({''});
    else
        xlabel('CA_x')
    end
    if q==1 || q==4
        yticklabels({''});
    else
        ylabel('CA_y')
    end
    text(1.2, 1.5, {['CPS_' '{Q' num2str(q) '}']}, 'FontSize', 11, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end
for q = 1:4
    caxis(ax(q), [0 60]); % color range
end
cb = colorbar; cb.Position = [.82 .15 .03 .75]; cb.Label.String = 'Time (min)';

saveas(gcf, ['Fig/CA_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'png');
saveas(gcf, ['Fig/CA_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'svg');


%% CA mean plot
figure('Units', 'centimeters', 'Position', [5 5 15 6]);
axes(gcf, 'Position', [0.1 0.2 0.3 0.75], 'FontSize', 9, 'Box', 'on', ...
        'XTick', -2:1:2, 'YTick', -2:.5:2, 'XLim', [-1 1], 'YLim', [-1 1], 'LineWidth', 1.5);
hold on;
plot([0 0], [-2 2], ':k', 'LineWidth', 1);
plot([-2 2], [0 0], ':k', 'LineWidth', 1);
for q = 1:4
    CA_q = trace.CA(find(trace.quadrant_2==q, 10, 'first'), :);
    CA_mean = mean(CA_q);
    quiver(0, 0, CA_mean(1), CA_mean(2), 'LineWidth', 2, 'MaxHeadSize', .8, 'Color', C(q,:));
end
xlabel('CA_x'); ylabel('CA_y');

axes(gcf, 'Position', [0.5 0.2 0.3 0.75], 'FontSize', 9, 'Box', 'on', ...
        'XTick', -2:1:2, 'YTick', -2:.5:2, 'XLim', [-1 1], 'YLim', [-1 1], 'LineWidth', 1.5);
hold on;
plot([0 0], [-2 2], ':k', 'LineWidth', 1);
plot([-2 2], [0 0], ':k', 'LineWidth', 1);
for q = 1:4
    CA_q = trace.CA(find(trace.quadrant_2==q, 10, 'last'), :);
    CA_mean = mean(CA_q);
    pp(q) = quiver(0, 0, CA_mean(1), CA_mean(2), 'LineWidth', 2, 'MaxHeadSize', .8, 'Color', C(q,:));
end
xlabel('CA_x');
legend(pp, {'CPS_{Q1}', 'CPS_{Q2}', 'CPS_{Q3}', 'CPS_{Q4}'}, 'FontSize', 8, 'Box', 'off', 'Position', [0.86 0.55 0.1 0.4]);

saveas(gcf, ['Fig/CA_mean_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'png');
saveas(gcf, ['Fig/CA_mean_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'svg');

%% Trajectory plot
figure('Units', 'centimeters', 'Position', [5 5 10 8]);
ax = axes(gcf, 'Position', [.1 .1 .64 .8], 'FontSize', 9, 'Box', 'on', 'LineWidth', 1.5, 'XColor', 'none', 'YColor', 'none', 'Color', 'none');
colormap('parula'); hold on;
viscircles([0 0], 50, 'Color', 'k');
viscircles([0 0], 5, 'Color', 'k');
scatter(trace.traj(:,1), trace.traj(:,2), 6, trace.time/60, 'filled', 'MarkerFaceAlpha', 0.7);
caxis(ax, [0 60])
cb = colorbar; cb.Position = [.82 .1 .03 .8]; cb.Label.String = 'Time (min)';
axis('equal')
saveas(gcf, ['Fig/Traj_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'png');
saveas(gcf, ['Fig/Traj_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'svg');

%% Distance plot
figure('Units', 'centimeters', 'Position', [5 5 10 5]); 
axes(gcf, 'Position', [0.15 0.25 0.8 0.7], 'FontSize', 9, 'LineWidth', 1.5);
hold on;
plot([0 60], [5 5], ':k', 'LineWidth', 1);
plot([0 60], [50 50], ':k', 'LineWidth', 1);
plot(trace.time/60, Distance, 'Color', 'k', 'LineWidth', 1.5);
xlim([0 60]); ylim([0 55]);
xlabel('Time (min)', 'FontSize', 11);
ylabel('Distance to origin', 'FontSize', 11);

saveas(gcf, ['Fig/Distance_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'png');
saveas(gcf, ['Fig/Distance_plot_' stimulation_mode{stimulation_mode_chosen} '_' training_program{training_program_chosen}], 'svg');

%%
close all;
end

end
