net_info = load('NeuralNetwork.mat');
env = Network(net_info);

observation = env.reset();
for k = 1:1000000
    action = compute_action(observation);
    [observation, reward, done] = env.step(action);
    env.render();

    if done
        observation = env.reset();
    end
end


function action = compute_action(observation)
    action = randi(60);
end