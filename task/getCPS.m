function [stim_CPS, time_probe] = getCPS(min_isi, max_isi, CPS, quadrant, stimulator)

% set CPS stimulation schedule

CPS_now = CPS{quadrant};

stim_CPS = struct();

% 
stim_CPS(1).spiking = 1;
stim_CPS(1).dt = -1;
stim_CPS(1).idx = stimulator(CPS_now.first);
stim_CPS(1).data = min_isi + (max_isi-min_isi) * rand() + (0:5e-3:20e-3);

stim_CPS(2).spiking = 1;
stim_CPS(2).dt = -1;
stim_CPS(2).idx = stimulator(CPS_now.second);
stim_CPS(2).data = stim_CPS(1).data(1) + CPS_now.interval_1 + (0:5e-3:20e-3);

stim_CPS(3).spiking = 1;
stim_CPS(3).dt = -1;
stim_CPS(3).idx = stimulator(CPS_now.probe);
stim_CPS(3).data = stim_CPS(2).data(1) + CPS_now.interval_2 + (0:5e-3:20e-3);

time_probe = stim_CPS(3).data(end);

end