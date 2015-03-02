module Appdynamics
    class Application
        attr_reader :controller, :application_id, :application_name

        def initialize controller, application_id, application_name
            @controller = controller
            @application_name = application_name
            @application_id = application_id
        end

        def name
            @application_name
        end

        def to_hash
            hsh = {
                application_name: @application_name,
                application_id: @application_id
            }
            hsh.merge!({nodes: @nodes.map{|node| node.to_hash}}) if @nodes
            hsh.merge!({metrics: @metrics.map{|node| node.to_hash}}) if @metrics
            hsh.merge!({tiers: @tiers.map{|node| node.to_hash}}) if @tiers
            hsh
        end

        def self.from_hash hsh, controller
            application = Application.new controller, hsh['application_id'], hsh['application_name']
            application.metrics = hsh['metrics'] if hsh['metrics']
            application.tiers = hsh['tiers'] if hsh['tiers']
            application.nodes = hsh['nodes'] if hsh['nodes']
            application
        end

        def nodes
            @nodes ||= controller.nodes_for self
        end

        def nodes= nodes
            @nodes = nodes.map{|node|
                Node.from_hash node, @controller, self
            }
        end

        def tiers
            @tiers ||= controller.tiers_for self
        end

        def tiers= tiers
            @tiers = tiers.map{|tier|
                Tier.from_hash tier, @controller, self
            }
        end

        def metrics
            @metrics ||= controller.metrics_for self
        end

        def metrics= metrics
            @metrics = metrics.map{|metric|
                Metric.from_hash metric, @controller, self
            }
        end

        def find_metric_by_name nam
            metric = nil
            metrics.each do |m|
                metric = m.find_by_name nam
                break unless metric.nil?
            end
            metric
        end

        def find_metric_by_path path
            metric = metrics.select{|metric| metric.name == path.first}.first
            return nil unless metric
            path.shift
            path.each do |metric_name|
                metric = metric.child_by_name metric_name
                return nil unless metric
            end
            metric
        end

        def relative_route *_
            "applications/#{application_id}"
        end
    end
end
