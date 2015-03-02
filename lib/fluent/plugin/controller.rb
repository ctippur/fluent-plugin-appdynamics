require 'uri'
module Appdynamics
    class Controller
        include HTTParty
        attr_reader :host_name, :account_name, :user_name, :password, :application_name, :application_id,
                    :base_uri, :applications, :nodes, :tiers

        def initialize host_name, account_name, user_name, password
            @host_name = host_name
            @account_name = account_name
            @user_name = user_name
            @password = password
            @base_uri = "http://#{host_name}/controller/rest"
            @auth = {username: "#{user_name}@#{account_name}", password: password}
        end

        def serialize
            YAML.dump self
        end

        def self.deserialize datum
            YAML.load datum
        end

        def to_hash
            hsh = {
                host_name: @host_name,
                account_name: @account_name,
                user_name: @user_name,
                password: @password
            }
            hsh.merge!({applications: @applications.map{|app| app.to_hash}}) if @applications
            hsh
        end

        def self.from_hash hsh
            controller = Controller.new hsh['host_name'], hsh['account_name'], hsh['user_name'], hsh['password']
            controller.applications = hsh['applications']
            controller
        end

        def applications
            return @applications unless @applications.nil?
            result = []
            begin
                result = self.class.get("#{@base_uri}/applications", options)
            rescue SocketError => ee
                raise Exception.new "Bad host name, #{ee}"
            end

            raise Exception.new "HTTP Error: #{result.response.code}" unless result.response.code == "200"

            @applications ||= result.map{|res|
                Application.new self, res["id"], res["name"]
            }
        end

        def applications= applications
            @applications = applications.map{|application|
                Application.from_hash application, self
            }
        end

        def reset_cache!
            @nodes = @tiers = @applications = nil
        end

        def get path, additional_options = {}
            result = self.class.get(URI.escape(path), options(additional_options))
            raise Exception.new "HTTP Error: #{result.response.code}" unless result.response.code == "200"
            result
        end

        def nodes_for application
            path = "#{base_uri}/#{application.relative_route}/nodes"
            result = get path
            result.map{|res|
                Node.new self, application, res
            }
        end

        def tiers_for application
            path = "#{base_uri}/#{application.relative_route}/tiers"
            result = get path
            result.map{|res|
                Tier.new self, application, res
            }
        end

        def metrics_for obj
            path = "#{base_uri}/#{obj.relative_route}"
            path += "/metrics" if obj.class == Application
            result = get path
            result.map{|res|
                Metric.new self, obj, res
            }
        end

        def metric_data_for metric, start_time, end_time, rollup = false
            path = "#{base_uri}/#{metric.relative_route(true)}"
            start_time = Time.parse start_time unless start_time.class == Time
            end_time = Time.parse end_time unless end_time.class == Time
            path = "#{base_uri}/#{metric.relative_route(true)}"
            additional_options = {
                'time-range-type' => "BETWEEN_TIMES",
                'start-time' => start_time.to_i * 1000,
                'end-time' => end_time.to_i * 1000,
                'rollup' => rollup
            }
            result = get path, options({query: additional_options})
            result
        end

        protected
        def options additional_options = {}
            base_options = {basic_auth: @auth}.merge additional_options
            base_options[:query] ||= {}
            base_options[:query][:output] ||= 'JSON'
            base_options[:query][:rollup] ||= false
            base_options
        end
    end
end
