addpath('..\network\')

net_info = load('NeuralNetwork_1205.mat');
bh_info = load('BehaviorData_1205.mat');
env = Network(net_info, bh_info);
algo = algo_paper();

%%
observation = env.reset();
flag = 0;
reward = 1;
for k = 1:1000000
    if env.time > 0.1*env.one_minute && flag==0
        env.switch_CPS(1,3);
        flag = 1;
    end
    action = algo.compute_action(observation, reward);
    [observation, reward, done] = env.step(action);
    env.render();
    algo.update(reward);
    if done
        observation = env.reset();
        reward = 1;
    end
end