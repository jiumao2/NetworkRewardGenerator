clear all; close all;

addpath('../lsm/csim');
addpath('../network');

getParameters;
load('NeuralNetwork_1205.mat');
load('BehaviorData_1205.mat');

%% perform task for one hour under CPS & RBS
perform_CPS_RBS_1hour;

%% perform task for one hour under CPS only
perform_CPSonly_1hour;

save('BehaviorData', 'CPS', 'CA_mean', 'T', 'trace_pre', 'trace_CPS_RBS_1hour', 'trace_CPSonly_1hour');

%% Fig. 2A
figure('Units', 'centimeters', 'Position', [12 2 10 8]); hold on;
plot(trace_CPS_RBS_1hour.time/one_minute, trace_CPS_RBS_1hour.distance, '-', 'Color', [0 0 0], 'Marker', '.');
plot(trace_CPSonly_1hour.time/one_minute, trace_CPSonly_1hour.distance, '-', 'Color', [.5 .5 .5], 'Marker', '.');

xlim([0 60.1]); xticks(0:10:60); xlabel('Time (min)');
ylim([0 50]); yticks([0 5 50]); ylabel('Distance');

saveas(gca, 'Fig_2_A', 'png');