function [stim_RBS, RBS_timepoint, RBS_electrode] = getRBS(min_interval, max_interval, duration, stimulator, n_electrode)

% set RBS stimulation schedule

RBS_interval = min_interval + (max_interval-min_interval)*rand(1, duration/min_interval);
RBS_timepoint = cumsum(RBS_interval);
RBS_timepoint(RBS_timepoint>duration) = [];
RBS_number = length(RBS_timepoint);
RBS_electrode = randi(n_electrode, [1, RBS_number]);

stim_RBS = struct();
for k = 1:n_electrode
    stim_RBS(k).spiking = 1;
    stim_RBS(k).dt = -1;
    stim_RBS(k).idx = stimulator(k);
    stim_RBS(k).data = RBS_timepoint(RBS_electrode==k);
end