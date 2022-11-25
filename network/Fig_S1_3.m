addpath('../lsm/csim')
getParameters;
Tsim = 3000;

noise = (70:1:120)*1e-9;
spike_per_min = zeros(length(noise),1);

for k = 1:length(noise)
    csim('destroy')
    csim('set','dt',dt);

    neuron = csim('create','LifNeuron');
    csim('set',neuron,'Vthresh',V_thresh);  % threshold  
    csim('set',neuron,'Trefract',T_refract); % refractory period
    csim('set',neuron,'Cm',C_m);        % tau_m = Cm * Rm
    csim('set',neuron,'Vreset',V_reset);   % V_reset
    csim('set',neuron,'Iinject',0);  % I_back
    csim('set',neuron,'Vinit',V_init);    % V_init
    csim('set',neuron,'Rm',R_m);
    csim('set',neuron,'Vresting',V_resting);
    csim('set',neuron,'Inoise',noise(k));

    r=csim('create','Recorder');
    csim('set',r,'dt',dt);
    csim('connect',r,neuron,'spikes');

    csim('simulate',Tsim);

    t=csim('get',r,'traces');
    spike_per_min(k) = length(t.channel(1).data)/Tsim*60;
end
%%
figure;
semilogy(noise*1e9,spike_per_min,'x-')
ylim([0.1,10])
xlabel('Std. of noise in self-firing neurons (nA)')
ylabel('Spontaneous bursting rate (per min)')
%%
figure;
plot(noise*1e9,spike_per_min,'x-')
