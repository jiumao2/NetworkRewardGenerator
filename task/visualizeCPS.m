clear
load CPS_all
addpath('../network/')
getParameters
figure('Units', 'centimeters', 'Position', [2 2 10 10]);
axes('XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-r_outer r_outer], 'YLim', [-r_outer r_outer], 'XTick', [], 'YTick', [], 'LineWidth', 2,'NextPlot','add');
hold on;
viscircles([0 0], r_outer, 'Color', 'k');
viscircles([0 0], r_inner, 'Color', 'k');
axis equal
t = cell(5,1);
for k = 1:length(CPS_all)
    cla;
    viscircles([0 0], r_outer, 'Color', 'k');
    viscircles([0 0], r_inner, 'Color', 'k');
    
    trace = CPS_all{k}.trace;
    for j = 1:5
        plot(trace(j).animat(:,1),trace(j).animat(:,2));
    end
    disp(k)
    pause
end


%%

choosed = [3,5,8,60];

figure('Units', 'centimeters', 'Position', [2 2 10 10]);
axes('XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [-r_outer r_outer], 'YLim', [-r_outer r_outer], 'XTick', [], 'YTick', [], 'LineWidth', 2,'NextPlot','add');
hold on;
viscircles([0 0], r_outer, 'Color', 'k');
viscircles([0 0], r_inner, 'Color', 'k');
axis equal

for k = 1:length(choosed)
%     cla;
%     viscircles([0 0], r_outer, 'Color', 'k');
%     viscircles([0 0], r_inner, 'Color', 'k');
    
    trace = CPS_all{choosed(k)}.trace;
    colors = colororder;
    for j = 1:5
        plot(trace(j).animat(:,1),trace(j).animat(:,2),'Color',colors(k,:));
    end
    disp(k)
%     pause
end

%%
choosed = [3,5,8,60];
CPS = cell(4, 1);
for q = 1:4
    CPS{q} = CPS_all{choosed(q)};
end
action_desired = [-1 -1; 1 -1; 1 1; -1 1]; % * sqrt(2)
CA_mean = cell(4,1);
T = cell(4,1);
for q = 1:4
    trace_CA_pre = [];
    for run = 1:5
        trace_CA_pre = [trace_CA_pre; CPS_all{choosed(q)}.trace(run).CA];
    end
    CA_mean{q} = mean(trace_CA_pre);
    T{q} = action_desired(q,:) ./ CA_mean{q};
end
save('BehaviorData_1208_3', 'CPS', 'CA_mean', 'T')


