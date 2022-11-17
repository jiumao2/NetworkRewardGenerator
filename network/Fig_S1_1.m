figure;
plot(loc_neuron(excitory_neurons,1),loc_neuron(excitory_neurons,2),'ro','MarkerFaceColor','r')
hold on
plot(loc_neuron(inhibitory_neurons,1),loc_neuron(inhibitory_neurons,2),'bs','MarkerFaceColor','b')

% excitory connections
x_excitory = [];
y_excitory = [];
for k = excitory_neurons
    for j = 1:n_neuron
        if connected(k,j) == 1 && rand()<0.05
            x_excitory = [x_excitory, loc_neuron(k,1), loc_neuron(j,1), NaN];
            y_excitory = [y_excitory, loc_neuron(k,2), loc_neuron(j,2), NaN];
        end
    end
end
plot(x_excitory, y_excitory, 'r-')

% inhibitory connections
x_inhibitory = [];
y_inhibitory = [];
for k = inhibitory_neurons
    for j = 1:n_neuron
        if connected(k,j) == 1 && rand()<0.05
            x_inhibitory = [x_inhibitory, loc_neuron(k,1), loc_neuron(j,1), NaN];
            y_inhibitory = [y_inhibitory, loc_neuron(k,2), loc_neuron(j,2), NaN];
        end
    end
end
plot(x_inhibitory, y_inhibitory, 'b-')

% electrode
plot(loc_electrode(:,1), loc_electrode(:,2), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 10)
