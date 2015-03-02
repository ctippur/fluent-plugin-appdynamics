require 'rspec'
require './lib/appdynamics'

describe Appdynamics::Node do
    let(:controller) { Appdynamics::Controller.deserialize(File.read("#{File.dirname(__FILE__)}/../fixtures/full_controller.yml")) }
    let(:application) { controller.applications.first }
    let(:node) { application.nodes.first }

    describe :to_hash do
        it "should be defined" do
            node.respond_to?(:to_hash).should == true
        end

        it "should have configuration fields" do
            [:id, :name, :type, :tierId, :tierName, :machineId, :machineName, :machineOSType, :ipAddresses,
                :machineAgentPresent, :machineAgentVersion, :appAgentPresent, :appAgentVersion,
                :nodeUniqueLocalId].each do |attr|
                node.to_hash[attr].should_not be_nil
            end
        end
    end

    describe :from_hash do
        let(:node_hash) { JSON.parse(File.read("#{File.dirname(__FILE__)}/../fixtures/node.json")) }
        it "should be a class method" do
            Appdynamics::Node.respond_to?(:from_hash).should == true
        end

        it "should require 3 parameters" do
            expect { Appdynamics::Node.from_hash(node_hash) }.to raise_error
        end

        it "should return a single node" do
            Appdynamics::Node.from_hash(node_hash, controller, application).class.should == Appdynamics::Node
        end
    end
end