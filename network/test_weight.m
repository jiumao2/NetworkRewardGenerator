clear all
close all
getParameters;
addpath('../lsm/csim');
csim('destroy')
    
i=csim('create','SpikingInputNeuron');
s=csim('create','DynamicSpikingSynapse');
n=csim('create','LifNeuron');

csim('set','randSeed',123456);

csim('set',n,'Vthresh',V_thresh);  % threshold  
csim('set',n,'Trefract',T_refract); % refractory period
csim('set',n,'Cm',C_m);        % tau_m = Cm * Rm
csim('set',n,'Vreset',V_reset);   % V_reset
csim('set',n,'Iinject',30e-9);  % I_back
csim('set',n,'Vinit',V_init);    % V_init
csim('set',n,'Rm',R_m);
csim('set',n,'Vresting',V_resting);
csim('set',n,'Inoise',0);

csim('set',s,'W',406e-9);
csim('set',s,'U',U);
csim('set',s,'D',D);
csim('set',s,'F',F);
csim('set',s,'u0',u0);
csim('set',s,'r0',R0);
csim('set',s,'tau',tau);

csim('connect',n,s);
csim('connect',s,i);

r=csim('create','Recorder');
csim('set',r,'dt',0.5e-3);

csim('connect',r,s,'psr');
csim('connect',r,n,'Vm');
csim('connect',r,n,'spikes');

S.spiking = 1;
S.dt = -1;
S.idx = i;
S.data = [0.0299    0.1349    0.1474    0.3325    0.3440    0.3649    0.4136  0.4331    0.4337    0.6088];

Tsim=4;
for k = 1:10
    csim('simulate',0.1);
    csim('set',n,'Iinject',0e-9);  % I_back
    csim('simulate',0.3);
    csim('set',n,'Iinject',30e-9);  % I_back
end

t=csim('get',r,'traces');

figure(1); clf reset;
subplot(3,1,1);
st=S.data;
line([st; st],[-0.045; -0.015]*ones(size(st)),'Color','k');
set(gca,'Xlim',[0 Tsim]);
title('input spike train');
axis off

subplot(3,1,2);
plot(t.channel(1).dt:t.channel(1).dt:Tsim,t.channel(1).data)
ylabel([t.channel(1).fieldName ' [A]']);
title('postsynaptic response');

subplot(3,1,3);
plot(t.channel(2).dt:t.channel(2).dt:Tsim,t.channel(2).data)
st=t.channel(3).data;
line([st; st],[-0.045; -0.015]*ones(size(st)),'Color','k');
ylabel([t.channel(2).fieldName ' [V]']);
xlabel('time [sec]');
title('membrane potential and spikes');

drawnow;