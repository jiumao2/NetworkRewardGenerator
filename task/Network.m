classdef Network < handle
    %Network the simulated network model
    
    properties
        % add more properties whenever needed
        neuron
        synapse
        recorder
        net_info
        fig
    end
    
    methods
        function obj = Network(net_info)
            % initialize
            addpath('../lsm/csim')
            csim('destroy')
            getParameters;
            csim('import', net_info.net)
            
            % set the properties
            obj.neuron = net_info.neuron;
            obj.synapse = net_info.synapse;
            obj.recorder = net_info.recorder;  
            obj.net_info = net_info;
            obj.fig = figure('Visible','off');
            obj.ax = axes(obj.fig);
            
            % warm up
            obj.warmup()
        end
        
        function observation = reset(obj)
            csim('reset');
            % reset the animat
            
            % return new observation
        end
        
        function warmup(obj)
            % when the network is reimported, STDP info will be lost
            % run another 10 minutes with RBS to stablize the network?
            
            
            % Calculate the transformations
            
            
            % switch the sensory mapping
            
            
            
        end
        
        function getRecordings(obj)
        end
        
        function getCPS(obj)
        end
        
        function getRBS(obj)
        end
        
        function getPTS(obj)
        end
        
        function getCA(obj)
        end
        
        function getQuadrant(obj)
        end
        
        function [observation, reward, done] = step(obj, action)
            % action: choose PTS (electrode, IPI...)
            % observation: Quadrant
            % reward: distance closer to the origin compared to last step (to be modified)
            % done: if the animat is outside the boundary
            
            % deliver RBS
            
            
            % deliver CPS
            
            
            % get recordings
            
            
            % move the animat
            
            
            % deliver PTS or RBS according to the performance
            
            
            % compute the observation and the reward
            
            
            % check if the task is done
            
            
            
        end
        
        function render(obj)
            % visualize the task
            set(obj.fig, 'Visible', 'on');
            clf(obj.ax)
            
            % plot the circles and the position of the animat
            
            drawnow;
        end

        

    end
end

