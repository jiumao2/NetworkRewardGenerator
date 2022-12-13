clear all; close all;
addpath('..\network\')

net_info = load('NeuralNetwork_1208.mat');
bh_info = load('BehaviorData_1208_2.mat');
env = Network(net_info, bh_info);
algo = algo_paper();
traj = {};

%%
rng(1211);
observation = env.reset();
env.render();
%
% env.stimulus_duration = 0.4 * env.one_millisecond;
% env.stimulus_amplitude = 6000e-9;

env.stimulus_duration = 20 * env.one_millisecond;
env.stimulus_amplitude = 200e-9;
%%
flag = 0;
dist_2 = [];
obs_last = [0,0];
dist_1 = norm(obs_last)-norm(observation);
obs_last = observation;

log_filename = ['log/log_',datestr(now,'yyyymmdd_hhMMss'),'.mat'];
log = [];
step_start = 0;
k = 0;

%%
trace_filename = ['trace/trace_long_paper_', datestr(now,'yyyymmdd_hhMMss'), '.mat'];
trace = struct();
trace.quadrant = env.getQuadrant();
trace.action = [];
trace.CA = [];
trace.traj = observation;
trace.weight = [];
trace.reward = [];
trace.time = 0;

%%
traj_this = [observation];
while env.time <= 1*env.one_hour
    k = k+1;
    if env.time > 10*env.one_minute && flag==0
        env.switch_CPS(1,3);
        flag = 1;
        step_start = k;
    end
    action = algo.compute_action(observation);
    if isnan(observation)
        observation = obs_last;
    end

    [observation, reward, done, CA] = env.step(action);
    disp(['action:',num2str(action),'  observation:',num2str(observation(1)),' ',num2str(observation(2)),'  reward:',num2str(reward),'  ',...
        'done:', num2str(done)]);
    env.render();
    
    quadrant_this = getQuadrant(observation);
    
    dist_2 = dist_1;
    dist_1 = norm(obs_last)-norm(observation);
    
    if norm(observation)<env.r_inner || dist_1>min(dist_2,0)
        algo.update(1, getQuadrant(obs_last));
    else
        algo.update(0, getQuadrant(obs_last));
    end
        
    obs_last = observation;
    traj_this = [traj_this;observation];
    
    trace.quadrant = [trace.quadrant; quadrant_this];
    trace.action = [trace.action; action];
    trace.CA = [trace.CA; CA];
    trace.traj = [trace.traj; observation];
    trace.reward = [trace.reward; reward];
    W = zeros(1, length(net_info.synapse));
    for s = 1:length(net_info.synapse)
        W(s) = csim('get', net_info.synapse(s), 'W');
    end
    trace.weight = [trace.weight; W];
    trace.time = [trace.time; env.time];

    if done
        log = [log;getQuadrant(observation),k-step_start];
        traj{length(traj)+1} = traj_this; 
        step_start = k;
        save(log_filename,'log','algo','traj')
        
        observation = env.reset();
        dist_2 = [];
        obs_last = [0,0];
        dist_1 = norm(obs_last)-norm(observation);
        done = false;
        traj_this = [observation];
    end
end

%%
log = [log;getQuadrant(observation),k-step_start];
traj{length(traj)+1} = traj_this;
step_start = k;
save(log_filename,'log','algo','traj')

done = false;
traj_this = observation;

save(trace_filename, 'trace');