module Appdynamics
    class Metric
        attr_accessor :type, :name
        attr_reader :controller, :parent

        def initialize controller, parent, attrs
            @controller = controller
            @parent = parent
            attrs.keys.each do |key|
                self.send "#{key}=", attrs[key]
            end
        end

        def to_hash
            hsh = {
                name: @name,
                type: @type
            }
            hsh.merge!({path: path})
            hsh.merge!({metrics: @metrics.map{|metric| metric.to_hash}}) if @metrics
            hsh
        end

        def self.from_hash hsh, controller, parent
            Metric.new controller, parent, hsh
        end

        def path
            return @path unless @path.nil?
            ar = [self.name]
            node = self
            while node.parent.class == Appdynamics::Metric && node = node.parent
                ar.unshift node.name
            end
            @path = ar
            @path
        end

        def path= pat
            @path = pat
        end

        def metrics= metrics
            @metrics = metrics.map {|metric|
                Metric.new @controller, self, metric
            }
        end

        def find_by_name nam
            return self if name == nam
            metric = nil
            metrics.each do |m|
                metric = m.find_by_name nam
                break unless metric.nil?
            end
            metric
        end

        def child_by_name nam
            metrics.select{|metric|
                metric.name == nam
            }.first
        end

        def metrics
            @metrics ||= controller.metrics_for self
        end

        def build_metrics_tree! tab_level = 0
            return if leaf?
            puts "#{'    ' * tab_level}Building tree for #{name} (#{type})"
            metrics.each do |m|
                m.build_metrics_tree!(tab_level + 1)
            end
        end

        def relative_route data_requested = false
            rel_path = "#{parent.relative_route(data_requested)}"
            case parent
                when Appdynamics::Metric
                    rel_path += "|#{name}"
                when Appdynamics::Application
                    if data_requested
                        rel_path += "/metric-data"
                    else
                        rel_path += "/metrics/"
                    end
                    rel_path += "?metric-path=#{name}"
            end
            rel_path
        end

        def data start_time, end_time, rollup = false
            raw_data = controller.metric_data_for(self, start_time, end_time, rollup).first
            raw_data["metricValues"]
        end

        protected
        def leaf?
            type == 'leaf'
        end
    end
end
