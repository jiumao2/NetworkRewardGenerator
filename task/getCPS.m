function [stim_CPS, time_probe, duration] = getCPS(min_isi, max_isi, CPS, quadrant, stimulator, dt, stimulus_amplitude, stimulus_duration)

% set CPS stimulation schedule
CPS_now = CPS{quadrant};
Elec = [CPS_now.first; CPS_now.second; CPS_now.probe];

stim_CPS = struct();

onset = zeros(3,1);
onset(1) = min_isi/2 + (max_isi-min_isi) * rand();
onset(2) = onset(1) + CPS_now.interval_1;
onset(3) = onset(2) + CPS_now.interval_2;
offset = onset + stimulus_duration;

time_probe = offset(end);
duration = offset(end) + 100e-3;

timepoint = zeros(1, round(duration/dt));
for e = 1:3
    timepoint(e, round(onset(e)/dt):round(offset(e)/dt)) = stimulus_amplitude;
    stim_CPS(e).spiking = 0;
    stim_CPS(e).dt = dt;
    stim_CPS(e).idx = stimulator(Elec(e));
    stim_CPS(e).data = timepoint(e,:);
end

end