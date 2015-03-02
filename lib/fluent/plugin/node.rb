module Appdynamics
    class Node

        ATTRIBUTES = [:id, :name, :type, :tierId, :tierName, :machineId, :machineName, :machineOSType, :ipAddresses,
                 :machineAgentPresent, :machineAgentVersion, :appAgentPresent, :appAgentVersion, :nodeUniqueLocalId]

        attr_accessor *ATTRIBUTES

        def initialize controller, application, attrs
            @controller = controller
            @application = application
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
            Node.new controller, application, hsh
        end

        def relative_route *_
            "#{application.relative_route}/nodes/#{id}"
        end
    end
end