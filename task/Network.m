classdef Network < handle
    %Network the simulated network model

    properties
        % add more properties whenever needed
        neuron
        synapse
        recorder
        stimulator
        net_info

        location
        location_last
        fig
        ax
        dot_animat
        trace = struct()

        min_isi
        max_isi
        inter_dur
        post_dur
        min_ipi
        max_ipi

        CPS
        T
        PTS

        time = 0;
        r_inner = 5;
        r_outer = 50;
        one_millisecond = 1e-3;
        one_second = 1;
        one_minute = 60;
        one_hour = 3600;
        color_animat = [1 0 0; 0 1 0; .5 .5 .5; 0 0 1];

        dt
        stimulus_duration
        stimulus_amplitude

        n_neuron_recorded = 5;
    end

    methods
        function obj = Network(net_info, bh_info)
            % initialize
            addpath('../lsm/csim');
            csim('destroy');
            getParameters;
            csim('import', net_info.net_with_RBS);

            % set the properties
            obj.neuron = net_info.neuron;
            obj.synapse = net_info.synapse;
            obj.recorder = net_info.recorder;
            obj.stimulator = net_info.stimulator;
            obj.net_info = net_info;

            obj.fig = figure('Visible','off', 'Units', 'centimeters', 'Position', [2 2 10 10], 'Renderer', 'opengl');
            obj.ax = axes(obj.fig,'XAxisLocation', 'origin', 'YAxisLocation', 'origin', 'XColor', 'none', 'YColor', 'none', ...
                'XLim', [-50 50], 'YLim', [-50 50], 'XTick', [], 'YTick', [], 'LineWidth', 2, 'NextPlot', 'add');
            viscircles(obj.ax, [0 0], obj.r_outer, 'Color', 'k');
            viscircles(obj.ax, [0 0], obj.r_inner, 'Color', 'k');
            axis(obj.ax, 'equal');
            obj.dot_animat = scatter(obj.ax, 0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none', 'LineWidth', 1);

            obj.reset();

            obj.CPS = bh_info.CPS;
            obj.T = bh_info.T;
            obj.PTS = obj.initPTS();

            obj.min_isi = 200*obj.one_millisecond; % min iter-stimulation interval
            obj.max_isi = 400*obj.one_millisecond; % max iter-stimulation interval
            obj.inter_dur = 5*obj.one_second; % duration between CPSs
            obj.post_dur = 100*obj.one_millisecond; % duration for recording after CPS probe
            obj.min_ipi = 400*obj.one_millisecond;
            obj.max_ipi = 800*obj.one_millisecond;

            obj.dt = csim('get', 'dt');
            obj.stimulus_duration = 20*obj.one_millisecond;
            obj.stimulus_amplitude = 200e-9;

%             warm up
            obj.warmup()
        end

        function observation = reset(obj)
            csim('reset');
            % reset the animat
            rho = randsrc(1, 1, [0:.1:obj.r_inner-.1; (0:.1:obj.r_inner-.1).^2 / sum((0:.1:obj.r_inner-.1).^2)]);
            theta = pi * (2*rand()-1);
            [x, y] = pol2cart(theta, rho);

            obj.location = [x, y];
            obj.trace.loc = [nan, nan; obj.location];
            obj.trace.move = nan(2,1);
            obj.trace.quad = [nan; obj.getQuadrant];
            
            % reset the figure
            cla(obj.ax);
            obj.dot_animat = scatter(obj.ax, 0, 0, 24, 'filled', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'none', 'LineWidth', 1);
            viscircles(obj.ax, [0 0], obj.r_outer, 'Color', 'k');
            viscircles(obj.ax, [0 0], obj.r_inner, 'Color', 'k');
            obj.location_last = [];

            % return new observation
            observation = obj.location;
        end

        function warmup(obj)
            csim('reset');
            % when the network is reimported, STDP info will be lost
            % run another 10 minutes with RBS to stablize the network?
            stim_RBS = obj.getRBS(1*obj.one_minute);
            csim('simulate', 1*obj.one_minute, stim_RBS);
        end

        function switch_CPS(obj, Qa, Qb)
            CPS_temp_a = obj.CPS{Qa};
            CPS_temp_b = obj.CPS{Qb};
            T_temp_a = obj.T{Qa};
            T_temp_b = obj.T{Qb};

            obj.T{Qa} = T_temp_b;
            obj.T{Qb} = T_temp_a;
            obj.CPS{Qa} = CPS_temp_b;
            obj.CPS{Qb} = CPS_temp_a;

            for p = 1:660
                PTS_temp_a = obj.PTS{Qa, p};
                PTS_temp_b = obj.PTS{Qb, p};

                obj.PTS{Qa, p} = PTS_temp_b;
                obj.PTS{Qb, p} = PTS_temp_a;
            end
        end

        function firing_rate = getRecordings(obj, time_probe)
            n_electrode = length(obj.recorder);
            firing_rate = zeros(n_electrode, 1);
            for k = 1:n_electrode
                R = csim('get', obj.recorder(k), 'traces');
                for n = 1:obj.n_neuron_recorded
                    firing_rate(k) = firing_rate(k) + sum(R.channel(n).data>time_probe) / obj.post_dur;
                end
            end
        end

        function PTS = initPTS(obj)
            % initialize PTSs pool
            n_electrode = length(obj.stimulator);
            laps = (-100:20:100) * obj.one_millisecond;
            n_laps = length(laps);

            PTS = cell(4, n_electrode*n_laps);
            for q = 1:4
                E1 = obj.CPS{q}.probe;
                for E2 = 1:n_electrode
                    for l = 1:n_laps
                        n = (E2-1)*n_laps + l;
                        PTS{q,n}(1).E1 = E1;
                        PTS{q,n}(1).E2 = E2;
                        PTS{q,n}(1).dt = laps(l);
                    end
                end
            end
        end

        function [stim_CPS, time_probe, duration] = getCPS(obj, quadrant)
            % set CPS stimulation schedule
            CPS_now = obj.CPS{quadrant};
            Elec = [CPS_now.first; CPS_now.second; CPS_now.probe];

            stim_CPS = struct();

            onset = zeros(3,1);
            onset(1) = obj.min_isi/2 + (obj.max_isi-obj.min_isi) * rand();
            onset(2) = onset(1) + CPS_now.interval_1;
            onset(3) = onset(2) + CPS_now.interval_2;
            offset = onset + obj.stimulus_duration;

            time_probe = offset(end);
            duration = offset(end) + 100e-3;

            timepoint = zeros(1, round(duration/obj.dt));
            for e = 1:3
                timepoint(e, round(onset(e)/obj.dt):round(offset(e)/obj.dt)) = obj.stimulus_amplitude;
                stim_CPS(e).spiking = 0;
                stim_CPS(e).dt = obj.dt;
                stim_CPS(e).idx = obj.stimulator(Elec(e));
                stim_CPS(e).data = timepoint(e, :);
            end
        end

        function stim_RBS = getRBS(obj, duration)
            % set RBS stimulation schedule
            n_electrode = length(obj.stimulator);
            RBS_interval = obj.min_isi + (obj.max_isi-obj.min_isi)*rand(1, duration/obj.min_isi);

            RBS_offset = cumsum(RBS_interval) + obj.stimulus_duration;
            RBS_offset(RBS_offset>duration) = [];
            RBS_offset = RBS_offset - obj.min_isi/2;
            RBS_onset = RBS_offset - obj.stimulus_duration;

            n_stimulation = length(RBS_onset);
            RBS_electrode = randi(n_electrode, [1, n_stimulation]);

            timepoint = zeros(n_electrode, round(duration/obj.dt));
            for s = 1:n_stimulation
                timepoint(RBS_electrode(s), round(RBS_onset(s)/obj.dt):round(RBS_offset(s)/obj.dt)) = obj.stimulus_amplitude;
            end

            stim_RBS = struct();
            for k = 1:n_electrode
                stim_RBS(k).spiking = 0;
                stim_RBS(k).dt = obj.dt;
                stim_RBS(k).idx = obj.stimulator(k);
                stim_RBS(k).data = timepoint(k, :);
            end

        end

        function stim_PTS = getPTS(obj, quadrant, action)
            % set PTS stimulation schedule under input of quadrant and action
            PTS_now = obj.PTS{quadrant, action};
            stim_PTS = struct();

            PTS_interval = obj.min_ipi + (obj.max_ipi-obj.min_ipi)*rand(1, ceil(obj.inter_dur/obj.min_ipi));

            PTS_offset = cumsum(PTS_interval) + obj.stimulus_duration;
            PTS_offset(PTS_offset>obj.inter_dur) = [];
            PTS_offset = PTS_offset - obj.min_ipi/2;
            PTS_onset = PTS_offset - obj.stimulus_duration;

            PTS_offset_2 = PTS_offset + PTS_now.dt;
            PTS_onset_2 = PTS_onset + PTS_now.dt;

            n_stimulation = length(PTS_onset);

            timepoint = zeros(2, round(obj.inter_dur/obj.dt));
            for s = 1:n_stimulation
                timepoint(1, round(PTS_onset(s)/obj.dt):round(PTS_offset(s)/obj.dt)) = obj.stimulus_amplitude;
                timepoint(2, round(PTS_onset_2(s)/obj.dt):round(PTS_offset_2(s)/obj.dt)) = obj.stimulus_amplitude;
            end

            % return PTS stimulation
            stim_PTS(1).spiking = 0;
            stim_PTS(1).dt = obj.dt;
            stim_PTS(1).idx = obj.stimulator(PTS_now.E1);
            stim_PTS(1).data = timepoint(1,:);

            stim_PTS(2).spiking = 0;
            stim_PTS(2).dt = obj.dt;
            stim_PTS(2).idx = obj.stimulator(PTS_now.E2);
            stim_PTS(2).data = timepoint(2,:);
        end

        function CA = getCA(obj, firing_rate)
            CA_x = sum(firing_rate.*(obj.net_info.col_electrode-4.5)) / sum(firing_rate);
            CA_y = sum(firing_rate.*(obj.net_info.row_electrode-4.5)) / sum(firing_rate);
            
            if isnan(CA_x)
                CA_x = 0;
            end
            if isnan(CA_y)
                CA_y = 0;
            end

            CA = [CA_x, CA_y];
        end

        function quadrant = getQuadrant(obj)
            N = size(obj.location, 1);
            quadrant = zeros(N,1);
            for i = 1:N
                theta = cart2pol(obj.location(i,1), obj.location(i,2));
                if theta>=0 && theta<pi/2
                    quadrant(i) = 1;
                elseif theta>=pi/2
                    quadrant(i) = 2;
                elseif theta<-pi/2
                    quadrant(i) = 3;
                elseif theta<0 && theta>=-pi/2
                    quadrant(i) = 4;
                end
            end
        end

        function [observation, reward, done] = step(obj, action)
            % action: choose PTS (electrode, IPI...)
            % observation: Quadrant
            % reward: distance closer to the origin compared to last step (to be modified)
            % done: if the animat is outside the boundary

            quadrant_pre = obj.getQuadrant();
            dist_to_origin_pre = hypot(obj.location(1), obj.location(2));

            % deliver RBS or PTS
            csim('reset');
            if ~action
                stim_RBS = obj.getRBS(obj.inter_dur);
                csim('simulate', obj.inter_dur, stim_RBS);
            else
                stim_PTS = obj.getPTS(quadrant_pre, action);
                csim('simulate', obj.inter_dur, stim_PTS);
            end
            obj.time = obj.time + csim('get', 't');

            % deliver CPS
            csim('reset');
            [stim_CPS, time_probe, duration] = obj.getCPS(quadrant_pre);
            csim('simulate', duration, stim_CPS);
            obj.time = obj.time + csim('get', 't');

            % get recordings
            firing_rate = obj.getRecordings(time_probe);

            % move the animat
            CA = obj.getCA(firing_rate);
            step_length = norm(obj.T{quadrant_pre} .* CA);
            step_scale = max(1,step_length/5);
            obj.location_last = obj.location;
            obj.location = obj.location + obj.T{quadrant_pre} .* CA * sqrt(2) ./step_scale;

            % compute the observation and the reward
            quadrant_post = obj.getQuadrant();
            dist_to_origin_post = hypot(obj.location(1), obj.location(2));
            observation = obj.location;

            if dist_to_origin_post <= obj.r_inner
                reward = 1;
            else
                if dist_to_origin_post <= dist_to_origin_pre
                    reward = 1;
                else
                    reward = 0;
                end
            end

            % check if the task is done
            if dist_to_origin_post >= obj.r_outer
                done = 1;
            else
                done = 0;
            end

        end

        function render(obj)
            % visualize the task
            set(obj.fig, 'Visible', 'on');

            % plot the position of the animat
            quadrant = obj.getQuadrant();
            scatter(obj.ax, obj.location(1), obj.location(2), 2, obj.color_animat(quadrant,:), 'filled');
            if ~isempty(obj.location_last)    
                plot(obj.ax, [obj.location_last(1),obj.location(1)], ...
                    [obj.location_last(2),obj.location(2)], '-', 'Color', [.6 .6 .6], 'LineWidth', 0.2);
            end
            
            obj.dot_animat.MarkerEdgeColor = [0 0 0];
            obj.dot_animat.MarkerFaceColor = obj.color_animat(quadrant,:);
            obj.dot_animat.XData = obj.location(1);
            obj.dot_animat.YData = obj.location(2);
            uistack(obj.dot_animat, 'top');
            title(obj.ax, sprintf('%.2f min', obj.time./obj.one_minute));
            drawnow;
        end

    end
end

