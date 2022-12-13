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
log_filename = ['log/log_greedy',datestr(now,'yyyymmdd_hhMMss'),'.mat'];
log = [];

%%
trace_filename = ['trace/trace_long_greedy_', datestr(now,'yyyymmdd_hhMMss'), '.mat'];
trace = struct();
trace.quadrant = env.getQuadrant();
trace.action = [];
trace.CA = [];
trace.traj = observation;
trace.weight = [];
trace.reward = [];
trace.Q = zeros(1, size(env.PTS,1)*size(env.PTS,2));
trace.time = 0;

%%
N = zeros(size(env.PTS,1), size(env.PTS,2));
Q = zeros(size(env.PTS,1), size(env.PTS,2));
epsilon = 0.2;

step_start = 0;
step = 0;
flag = 0;
num_bin = 1;

k = 0;
traj_this = observation;
while env.time <= 1*env.one_hour
    k = k+1;
    if env.time > 10*env.one_minute && flag==0
        env.switch_CPS(1,3);
        flag = 1;
        step_start = k;
        msgbox('switch');
    end

    step = step+1;
    quadrant = env.getQuadrant();
    if norm(observation) <= env.r_inner
        action = 0;
    else
        action = getAction(Q, quadrant, epsilon);
    end
    obs_last = observation;

    [observation, r, done, CA] = env.step(action);

    traj_this = [traj_this; observation];
    movement = observation - obs_last;
    desired_dir = -obs_last;
    angle = acos(movement*desired_dir'/(norm(movement)*norm(desired_dir)));
    reward = 2 - round(4*angle/pi);

    if action
        N(quadrant, action) = N(quadrant, action) + 1;
        Q = updateQ(Q, N, quadrant, action, reward);
    end

    trace.quadrant = [trace.quadrant; quadrant];
    trace.action = [trace.action; action];
    trace.CA = [trace.CA; CA];
    trace.traj = [trace.traj; observation];
    trace.reward = [trace.reward; reward];
    trace.Q = [trace.Q; Q(:)'];
    W = zeros(1, length(net_info.synapse));
    for s = 1:length(net_info.synapse)
        W(s) = csim('get', net_info.synapse(s), 'W');
    end
    trace.weight = [trace.weight; W];
    trace.time = [trace.time; env.time];

    num_bin = num_bin + 1;

    env.render();
    title(env.ax, ['time-in:',num2str(env.time),'  quadrant:',num2str(quadrant),'  action:',num2str(action),'  reward:',num2str(reward)]);
    drawnow;

    if done
        log = [log;getQuadrant(observation),k-step_start];
        traj{length(traj)+1} = traj_this;
        step_start = k;
        save(log_filename,'log','Q','traj')

        observation = env.reset();
        done = false;
        traj_this = observation;
    end
end
log = [log;getQuadrant(observation),k-step_start];
traj{length(traj)+1} = traj_this;
step_start = k;
save(log_filename,'log','Q','traj')

done = false;
traj_this = observation;

save(trace_filename, 'trace');

%%
function action = getAction(Q, quadrant, epsilon)
if rand() > epsilon
    max_Q = max(Q(quadrant,:));
    max_action = find(Q(quadrant,:)==max_Q);
    action = max_action(randperm(length(max_action), 1));
else
    action = randi(size(Q,2));
end
end

%%
function Q = updateQ(Q, N, quadrant, action, reward)
    Q(quadrant, action) = Q(quadrant, action) + (reward-Q(quadrant, action)) / N(quadrant, action); % N(quadrant, action)^0.5
end

%%
function Q = switchQ(Q, Qa, Qb)
    Q_temp_a = Q(Qa,:);
    Q_temp_b = Q(Qb,:);
    
    Q(Qa, :) = Q_temp_b;
    Q(Qb, :) = Q_temp_a;
end