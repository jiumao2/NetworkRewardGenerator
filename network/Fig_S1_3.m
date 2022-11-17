clear all
close all
addpath('../lsm/csim')
getParameters;
Tsim=1200;
rng(rand_seed)


I_noise = 10:10:120;
rate = zeros(size(I_noise));

for k = 1:length(I_noise)
csim('destroy');
csim('set','randSeed',rand_seed);
csim('set','dt',dt);
csim('set','nThreads',16);    
    
n=csim('create','LifNeuron');
csim('set',n,'Vthresh',V_thresh);  % threshold  
csim('set',n,'Trefract',T_refract); % refractory period
csim('set',n,'Cm',C_m);        % tau_m = Cm * Rm
csim('set',n,'Vreset',V_reset);   % V_reset
csim('set',n,'Vinit',V_init);    % V_init
csim('set',n,'Rm',R_m);
csim('set',n,'Vresting',V_resting);
csim('set',n,'Inoise',I_noise(k)*1e-9);

r=csim('create','Recorder');
csim('set',r,'dt',0.5e-3);

csim('connect',r,n,'Vm');
csim('connect',r,n,'spikes');

csim('simulate',Tsim);

t=csim('get',r,'traces');
st=t.channel(2).data;
rate(k) = length(st);
end
figure;
plot(I_noise,rate/20)
figure()
plot(t.channel(1).dt:t.channel(1).dt:Tsim,t.channel(1).data)
st=t.channel(2).data;
line([st; st],[-0.045; -0.015]*ones(size(st)),'Color','k');
ylabel([t.channel(1).fieldName ' [V]']);
xlabel('time [sec]');
ylim([-0.08,0])
hold on
yline(V_thresh)
title('membrane potential and spikes');

drawnow;