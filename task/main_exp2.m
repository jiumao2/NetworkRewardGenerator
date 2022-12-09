addpath('..\network\')

net_info = load('NeuralNetwork_1208.mat');
bh_info = load('BehaviorData_1208.mat');
env = Network(net_info, bh_info);
algo = algo_paper();
traj = {};
%%
observation = env.reset();
flag = 0;
dist_2 = [];
obs_last = [0,0];
dist_1 = norm(obs_last)-norm(observation);
obs_last = observation;

log_filename = ['log/log_',datestr(now,'yyyymmdd_hhMMss'),'.mat'];
log = [];
step_start = 0;

traj_this = [observation];
for k = 1:1000000
    if env.time > 10*env.one_minute && flag==0
        env.switch_CPS(1,3);
        flag = 1;
        step_start = k;
    end
    action = algo.compute_action(observation);
    [observation, reward, done] = env.step(action);
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