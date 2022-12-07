addpath('..\network\')

net_info = load('NeuralNetwork_1205.mat');
bh_info = load('BehaviorData_1205.mat');
env = Network(net_info, bh_info);
algo = algo_paper();

%%
observation = env.reset();
for k = 1:1000000
    action = algo.compute_action(observation);
    [observation, reward, done] = env.step(action);
    env.render();
    algo.update(reward);
    if done
        observation = env.reset();
    end
end