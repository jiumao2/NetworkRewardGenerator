%%
trace_greedy = load('trace_short_greedy_20221213_100903.mat');
trace_paper = load('trace_short_paper_20221213_102003.mat');
trace_withoutPTS = load('trace_short_without_PTS_20221213_101546.mat');
% trace_greedy = load('trace_long_greedy_20221213_111436.mat');
% trace_paper = load('trace_long_paper_20221213_111707.mat');
% trace_withoutPTS = load('trace_long_without_PTS_20221213_112122.mat');
[~, score] = pca([trace_greedy.trace.weight; trace_paper.trace.weight; trace_withoutPTS.trace.weight]);

%%
smooth_window = 10;
figure('Units', 'centimeters', 'Position', [3 3 12 8]); colormap('parula');
axes('Position', [.1 .1 .6 .8], 'FontSize', 10)
scatter3(smooth(score(1:size(trace_greedy.trace.weight,1), 1), smooth_window), ...
    smooth(score(1:size(trace_greedy.trace.weight,1), 2), smooth_window), ...
    smooth(score(1:size(trace_greedy.trace.weight,1), 3), smooth_window), ...
    16, trace_greedy.trace.time(2:end)/60, 'fill', 'Marker', 'o');
hold on;
scatter3(smooth(score(size(trace_greedy.trace.weight,1)+1:size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1), 1), smooth_window), ...
    smooth(score(size(trace_greedy.trace.weight,1)+1:size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1), 2), smooth_window), ...
    smooth(score(size(trace_greedy.trace.weight,1)+1:size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1), 3), smooth_window), ...
    16, trace_paper.trace.time(2:end)/60,'fill', 'Marker', 'd');
scatter3(smooth(score(size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1)+1:size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1)+size(trace_withoutPTS.trace.weight,1), 1), smooth_window), ...
    smooth(score(size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1)+1:size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1)+size(trace_withoutPTS.trace.weight,1), 2), smooth_window), ...
    smooth(score(size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1)+1:size(trace_greedy.trace.weight,1)+size(trace_paper.trace.weight,1)+size(trace_withoutPTS.trace.weight,1), 3), smooth_window), ...
    32, trace_withoutPTS.trace.time(2:end)/60,'fill', 'Marker', 'x', 'MarkerEdgeColor', 'flat');
xlabel('PC1', 'FontSize', 10); ylabel('PC2', 'FontSize', 10); zlabel('PC3', 'FontSize', 10)
legend({'ε-greedy', 'Chao 2008', 'without PTS'}, 'Location', 'northeast', 'box', 'off');
cb = colorbar; cb.Label.String = 'Time (s)'; cb.Label.FontSize = 10; cb.Position = [0.8 0.1 0.03 0.8];