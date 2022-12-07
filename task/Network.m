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
        fig
        ax

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
        one_milisecond = 1e-3;
        one_second = 1;
        one_minute = 60;
        one_hour = 3600;

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

            obj.location = obj.reset();
            obj.fig = figure('Visible','off');
            obj.ax = axes(obj.fig);

            obj.CPS = bh_info.CPS;
            obj.T = bh_info.T;
            obj.PTS = obj.initPTS();

            obj.min_isi = 200*obj.one_milisecond; % min iter-stimulation interval
            obj.max_isi = 400*obj.one_milisecond; % max iter-stimulation interval
            obj.inter_dur = 5*obj.one_second; % duration between CPSs
            obj.post_dur = 100*obj.one_milisecond; % duration for recording after CPS probe
            obj.min_ipi = 400*obj.one_milisecond;
            obj.max_ipi = 800*obj.one_milisecond;

            % warm up
            obj.warmup()
        end

        function location = reset(obj)
            csim('reset');
            % reset the animat
            rho = randsrc(1, 1, [0:.1:obj.r_inner-.1; (0:.1:obj.r_inner-.1).^2 / sum((0:.1:obj.r_inner-.1).^2)]);
            theta = pi * (2*rand()-1);
            [x, y] = pol2cart(theta, rho);

            % return new observation
            location = [x, y];
        end

        function warmup(obj)
            csim('reset');
            % when the network is reimported, STDP info will be lost
            % run another 10 minutes with RBS to stablize the network?
            stim_RBS = obj.getRBS(1*obj.one_minute);
            csim('simulate', 0.1*obj.one_minute, stim_RBS);
        end

        function switch_CPS(obj, Qa, Qb)
            CPS_temp_a = obj.CPS{Qa};
            CPS_temp_b = obj.CPS{Qb};

            obj.CPS{Qa} = CPS_temp_b;
            obj.CPS{Qb} = CPS_temp_a;
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
            laps = (-100:20:100) * obj.one_milisecond;
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

        function [stim_CPS, time_probe] = getCPS(obj, quadrant)
            % set CPS stimulation schedule
            CPS_now = obj.CPS{quadrant};
            stim_CPS = struct();

            % return CPS stimulation and the time of last probe stimulation
            stim_CPS(1).spiking = 1;
            stim_CPS(1).dt = -1;
            stim_CPS(1).idx = obj.stimulator(CPS_now.first);
            stim_CPS(1).data = obj.min_isi + (obj.max_isi-obj.min_isi) * rand() + (0:5e-3:20e-3);

            stim_CPS(2).spiking = 1;
            stim_CPS(2).dt = -1;
            stim_CPS(2).idx = obj.stimulator(CPS_now.second);
            stim_CPS(2).data = stim_CPS(1).data(1) + CPS_now.interval_1 + (0:5e-3:20e-3);

            stim_CPS(3).spiking = 1;
            stim_CPS(3).dt = -1;
            stim_CPS(3).idx = obj.stimulator(CPS_now.probe);
            stim_CPS(3).data = stim_CPS(2).data(1) + CPS_now.interval_2 + (0:5e-3:20e-3);

            time_probe = stim_CPS(3).data(end);
        end

        function stim_RBS = getRBS(obj, dur)
            % set RBS stimulation schedule
            n_electrode = length(obj.stimulator);
            RBS_interval = obj.min_isi + (obj.max_isi-obj.min_isi)*rand(1, dur/obj.min_isi);
            RBS_electrode = randi(n_electrode, [1, length(RBS_interval)]);
            RBS_timepoint = [];
            for s = 1:5
                RBS_timepoint = [RBS_timepoint cumsum(RBS_interval) + (s-1)*5*obj.one_milisecond;];
            end
            RBS_timepoint = sort(RBS_timepoint);
            RBS_timepoint(RBS_timepoint>dur) = [];
            RBS_number = length(RBS_timepoint);
            RBS_electrode = repmat(RBS_electrode, 5, 1);
            RBS_electrode = RBS_electrode(1:RBS_number);

            % return RBS stimulation
            stim_RBS = struct();
            for k = 1:n_electrode
                stim_RBS(k).spiking = 1;
                stim_RBS(k).dt = -1;
                stim_RBS(k).idx = obj.stimulator(k);
                stim_RBS(k).data = RBS_timepoint(RBS_electrode==k);
            end
        end

        function stim_PTS = getPTS(obj, quadrant, action)
            % set PTS stimulation schedule under input of quadrant and action
            PTS_now = obj.PTS{quadrant, action};
            stim_PTS = struct();

            PTS_interval = obj.min_ipi + (obj.max_ipi-obj.min_ipi)*rand(1, ceil(obj.inter_dur/obj.min_ipi));
            PTS_timepoint = [];
            for s = 1:5
                PTS_timepoint = [PTS_timepoint cumsum(PTS_interval) + (s-1)*5*obj.one_milisecond];
            end
            PTS_timepoint = sort(PTS_timepoint);
            PTS_timepoint(PTS_timepoint>obj.inter_dur) = [];
            PTS_timepoint = PTS_timepoint - 200*obj.one_milisecond;

            % return PTS stimulation
            stim_PTS(1).spiking = 1;
            stim_PTS(1).dt = -1;
            stim_PTS(1).idx = obj.stimulator(PTS_now.E1);
            stim_PTS(1).data = PTS_timepoint;

            stim_PTS(2).spiking = 1;
            stim_PTS(2).dt = -1;
            stim_PTS(2).idx = obj.stimulator(PTS_now.E2);
            stim_PTS(2).data = PTS_timepoint + PTS_now.dt;
        end

        function CA = getCA(obj, firing_rate)
            CA_x = sum(firing_rate.*(obj.net_info.col_electrode-4.5)) / sum(firing_rate);
            CA_y = sum(firing_rate.*(obj.net_info.row_electrode-4.5)) / sum(firing_rate);

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

            % deliver CPS
            csim('reset');
            [stim_CPS, time_probe] = obj.getCPS(quadrant_pre);
            csim('simulate', time_probe+obj.post_dur, stim_CPS);
            obj.time = obj.time + csim('get', 't');

            % get recordings
            firing_rate = obj.getRecordings(time_probe);

            % move the animat
            CA = obj.getCA(firing_rate);
            obj.location = obj.location + obj.T{quadrant_pre} .* CA * sqrt(2);

            % deliver PTS or RBS according to the performance


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
            clf(obj.ax)

            % plot the circles and the position of the animat

            drawnow;
        end



    end
end

