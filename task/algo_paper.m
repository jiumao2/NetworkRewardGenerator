classdef algo_paper < handle
    %ALGO_PAPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        prob
        r_inner
        observation
        action
    end
    
    methods
        function obj = algo_paper()
            %ALGO_PAPER Construct an instance of this class
            %   Detailed explanation goes here
            obj.prob = ones(4,660);
            obj.r_inner = 5;
        end
        
        function action = compute_action(obj, observation, reward)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            quadrant = getQuadrant(observation);
            if norm(observation) < obj.r_inner
                action = 0;
            else
                if reward==0
                    action = obj.random_choose(obj.prob(quadrant,:));
                else
                    action = 0;
                end
            end
            
            obj.observation = observation;
            obj.action = action;
        end
        
        function action = sample(obj)
            action = randi(660);
        end
        
        function update(obj, reward)
            if obj.action==0
                return
            end
            
            quadrant = getQuadrant(obj.observation);
            if reward<=0 && sum(obj.prob(quadrant,obj.action),'all')>1
                obj.prob(quadrant,obj.action) = obj.prob(quadrant,obj.action)-1;
            elseif reward>=1
                obj.prob(quadrant,obj.action) = obj.prob(quadrant,obj.action)+1;
            end
        end
        
        function out = random_choose(obj, prob)
            prob = prob./sum(prob);
            out = find(cumsum(prob)>rand(),1);
        end
            
    end
end

