getParameters;
% spk_time = [0.0299    0.1349    0.1474    0.3325    0.3440    0.3649    0.4136  0.4331    0.4337    0.6088]; % ms
spk_time = [];
T_refract = 2e-3; % ms
var_noise = 100e-9; % nA
W = 2000e-9; % A
V_resting = -60*1e-3; % V
V_thresh = -45*1e-3;
V_reset = -60*1e-3;
V_init = -60*1e-3;

U = 0.4;
D = 1;
R = 1-U;
u0 = 0.4;
u = u0;

Tsim = 1;
t = 0:dt:Tsim;
st = [];

V_m = V_init*ones(length(t),1);
I_syn = zeros(length(t),1);
refract_steps = 0;
for k = 2:length(t)
    if any(abs(spk_time-t(k))<1e-6)
        temp = spk_time(spk_time<t(k)-1e-6);
        if isempty(temp)
            u = u0;
            R = 1;
        else
            u = u*exp(-(t(k)-temp(end))/tau)+U*(1-u*exp(-(t(k)-temp(end))/tau));
            R = R*(1-u)*exp(-(t(k)-temp(end))/D)+1-exp(-(t(k)-temp(end))/D);
        end
        I_syn(k) = W*R*u;
    else
        temp = spk_time(spk_time<t(k)-1e-6);
        if isempty(temp)
            I_syn(k) = 0;
        else
            I_syn(k) = W*exp(-(t(k)-temp(end))/tau)*R*u;
        end
    end
    
    if refract_steps > 0
        V_m(k) = V_reset;
        refract_steps = refract_steps-1;
        continue
    end

    I_noise = var_noise*randn();
    dvm_dt = @(V_m)1/tau_m*(-(V_m-V_resting)+R_m*(I_syn(k)-+I_noise));
    V_m(k) = rungekutta(dvm_dt,dt,V_m(k-1));
    if V_m(k) > V_thresh
        V_m(k) = 0;
        st = [st, t(k)];
        refract_steps = round(T_refract/dt);
    end
end


figure;
% subplot(3,1,1);
% line([spk_time; spk_time],[-0.045; -0.015]*ones(size(spk_time)),'Color','k');
% set(gca,'Xlim',[0 Tsim]);
% title('input spike train');
% axis off


subplot(3,1,2);
plot(t,I_syn*1e9)
ylabel('nA');
ylim([0,1000])
title('postsynaptic response');

subplot(3,1,3);
plot(t,V_m*1000)
line([st; st],[-0.045; -0.015]*ones(size(st)),'Color','k');
ylabel('mV');
xlabel('time [sec]');
xlim([0,Tsim])
ylim([-100,0])
title('membrane potential and spikes');
