function [stim_RBS, RBS_electrode] = getRBS(min_interval, max_interval, duration, stimulator, n_electrode, dt, stimulus_amplitude, stimulus_duration)

% set RBS stimulation schedule
RBS_interval = min_interval + (max_interval-min_interval)*rand(1, duration/min_interval);

RBS_offset = cumsum(RBS_interval) + stimulus_duration;
RBS_offset(RBS_offset>duration) = [];
RBS_offset = RBS_offset - min_interval/2;
RBS_onset = RBS_offset - stimulus_duration;

n_stimulation = length(RBS_onset);
RBS_electrode = randi(n_electrode, [1, n_stimulation]);

timepoint = zeros(n_electrode, round(duration/dt));
for s = 1:n_stimulation
    timepoint(RBS_electrode(s), round(RBS_onset(s)/dt):round(RBS_offset(s)/dt)) = stimulus_amplitude;
end

stim_RBS = struct();
for k = 1:n_electrode
    stim_RBS(k).spiking = 0;
    stim_RBS(k).dt = dt;
    stim_RBS(k).idx = stimulator(k);
    stim_RBS(k).data = timepoint(k, :);
end

