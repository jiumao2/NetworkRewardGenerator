figure;
W_temp = W(excitory_neurons,:);
connected_temp = connected(excitory_neurons,:);
histogram(W_temp(connected_temp==1), 'BinWidth', 0.001)
xlim([0,0.1])
xlabel('Synaptic weights')
ylabel('Number of synapses')