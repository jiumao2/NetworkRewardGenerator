classdef Network < handle
    %Network the simulated network model
    
    properties
        neuron
        synapse
        net
        dt
        amplitude
        stimulus
        t_recording
        t_total
        rec_spikes
        net_info
    end
    
    methods
        function obj = Network(net_info)
            addpath('../lsm/csim')
            csim('destroy')
            getParameters;
            csim('import', net_info.net)
            obj.neuron = net_info.neuron;
            obj.synapse = net_info.synapse;
            obj.rec_spikes = net_info.rec_spikes;
            obj.net = net_info.net;
            obj.dt = dt;
            obj.amplitude = stimulus_amplitude;
            obj.stimulus = zeros(n_neuron, round(1./obj.dt));
            obj.t_recording = t_recording;
            obj.t_total = 0;
            
            obj.net_info = net_info;
            % warm up
            obj.step_net(10);
        end
        
        function reset(obj)
            csim('destroy');
            obj.t_total = 0;
            csim('import', obj.net);
        end
        
        function recordings = get_recordings(obj, neurons)
            recordings = zeros(size(neurons,1),1);
            obj.step_net(obj.t_recording);
            for k = 1:size(recordings,1)
                temp = 0;
                for j = 1:size(recordings,2)
                    trace = csim('get',obj.rec_spikes(neurons(k,j)),'traces');
                    spike_count = sum(trace.channel.data(trace.channel.data>obj.t_total-obj.t_recording));
                    temp = temp+spike_count/obj.t_recording;
                end
                recordings(k) = temp./size(recordings,2);
            end
        end
        
        function save_net(obj,filename)
            obj.net = csim('export');
            network = obj;
            save(filename,'network')
        end
        
        function stimulate(obj, neurons, ipi, duration, frequency)
            t = obj.dt:obj.dt:duration;
            steps_single = round(duration/frequency/obj.dt);
            steps_interval = round(ipi/obj.dt);
            steps_pulse = steps_single -steps_interval;
            
            for k = 1:length(t)
                if mod(k,steps_single) <= steps_pulse
                    obj.stimulus(neurons,k) = obj.stimulus(neurons,k)+obj.amplitude;
                end
            end
        end
        
        function step_net(obj, Tsim)
            t = 1:round(Tsim./obj.dt);
            if length(t)<=size(obj.stimulus,2)
                t_con = 1;
                for k = 1:length(t)
                    if k<length(t) && all(obj.stimulus(:,k)==obj.stimulus(:,k+1))
                        t_con = t_con+1;
                        continue
                    end
                    
                    for j = 1:length(obj.neuron)
                        csim('set',obj.neuron(j),'Iinject',obj.stimulus(j,k));
                    end
                    csim('simulate', obj.dt*t_con);
                    t_con=1;
                end
                len_unstimulated = size(obj.stimulus,2) - length(t);
                obj.stimulus(:,1:len_unstimulated) = obj.stimulus(:,end-len_unstimulated+1:end);
                obj.stimulus(:,length(t)+1:end) = 0;
            else
                t_con = 1;
                for k = 1:size(obj.stimulus,2)
                    if k<size(obj.stimulus,2) && all(obj.stimulus(:,k)==obj.stimulus(:,k+1))
                        t_con = t_con+1;
                        continue
                    end
                    
                    for j = 1:length(obj.neuron)
                        csim('set',obj.neuron(j),'Iinject',obj.stimulus(j,k));
                    end
                    csim('simulate', obj.dt*t_con)
                    t_con=1;
                end      
                csim('simulate', obj.dt*(length(t)-size(obj.stimulus,2)));
                obj.stimulus(:,:) = 0;
            end
            obj.t_total = obj.t_total + Tsim;
        end
        
        function run_with_RBS(obj, Tsim)
            for t = 1:Tsim
                for k = 1:round(1/obj.dt)
                    if rand()<3*obj.dt
                        neurons = obj.net_info.neurons_stimulated_electrode(randi(60),:);
                        obj.stimulus(neurons,k:min(size(obj.stimulus,2),k+30)) = ...
                            obj.stimulus(neurons,k:min(size(obj.stimulus,2),k+30)) + obj.amplitude;
                    end
                end
                obj.step_net(1);
            end
        end
    end
end

