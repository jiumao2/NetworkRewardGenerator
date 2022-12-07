addpath('..\network\')

net_info = load('NeuralNetwork_1205.mat');
bh_info = load('BehaviorData.mat');
env = Network(net_info, bh_info);

%%
observation = env.reset();
for k = 1:1000000
    action = compute_action(observation);
    [observation, reward, done] = env.step(action);
    env.render();

    if done
        observation = env.reset();
    end
end

Q = zeros(4, 660);

function action = compute_action(observation)
    action = randi(660);
end