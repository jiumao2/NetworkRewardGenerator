net_info = load('nets/Net_seed_1_3600.mat');
n = Network(net_info);
%%
n.step_net(1);
%%
n.get_recordings(net_info.neurons_recored_electrode)
%%
n.stimulate(1:5,0.2,1,3);
%%
tic
n.run_with_RBS(60);
toc