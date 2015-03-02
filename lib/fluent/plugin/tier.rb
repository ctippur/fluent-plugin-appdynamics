module Appdynamics
    class Tier
        ATTRIBUTES = [:id, :agentType, :description, :name, :numberOfNodes, :type]

        attr_accessor *ATTRIBUTES
        attr_accessor :application, :controller

        def initialize controller, application, attrs
            @application = application
            @controller = controller
            attrs.keys.each do |key|
                self.send "#{key}=", attrs[key]
            end
        end

        def to_hash
            ATTRIBUTES.inject({}){|hsh, attr|
                hsh[attr] = self.send(attr)
                hsh
            }
        end

        def self.from_hash hsh, controller, application
            Tier.new controller, application, hsh
        end

        def relative_route *_
            "#{application.relative_route}/tiers/#{id}"
        end
    end
end
