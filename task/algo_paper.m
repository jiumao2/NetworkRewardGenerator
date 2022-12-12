classdef algo_paper < handle
    %ALGO_PAPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        prob
        r_inner
        action_last
        action_next
    end
    
    methods
        function obj = algo_paper()
            %ALGO_PAPER Construct an instance of this class
            %   Detailed explanation goes here
            obj.prob = ones(4,660);
            obj.r_inner = 5;
            obj.action_last = 0;
            obj.action_next = [];
        end
        
        function action = compute_action(obj, observation)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if norm(observation) < obj.r_inner
                action = 0;
                obj.action_last = action;
                return 
            end
            
            if ~isempty(obj.action_next)
                action = obj.action_next;
            else
                quadrant = getQuadrant(observation);
                action = obj.random_choose(obj.prob(quadrant,:));
            end
            obj.action_last = action;
        end
        
        function action = sample(obj)
            action = randi(660);
        end
        
        function update(obj, reward, quadrant)
            if reward == 1 && obj.action_last ~= 0
                obj.action_next = obj.action_last;
                obj.prob(quadrant,obj.action_last) = obj.prob(quadrant,obj.action_last)+1;
            elseif reward == 0 && obj.action_last ~= 0 && sum(obj.prob(quadrant,:),'all')>1
                obj.prob(quadrant,obj.action_last) = obj.prob(quadrant,obj.action_last)-1;
                obj.action_next = [];
            else
                obj.action_next = [];
            end

        end
        
        function out = random_choose(obj, prob)
            prob = prob./sum(prob);
            out = find(cumsum(prob)>rand(),1);
        end
            
    end
end

