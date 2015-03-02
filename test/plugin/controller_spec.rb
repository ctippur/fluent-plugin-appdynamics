require 'rspec'
require './lib/appdynamics'

describe Appdynamics::Controller do
    context "with all applications, nodes, tiers, and metrics populated" do
        let(:controller) { Appdynamics::Controller.deserialize(File.read("#{File.dirname(__FILE__)}/../fixtures/full_controller.yml")) }
        describe :to_hash do
            it "should be defined" do
                controller.respond_to?(:to_hash).should == true
            end

            it "should have configuration fields" do
                controller.to_hash[:host_name].should_not be_nil
                controller.to_hash[:account_name].should_not be_nil
                controller.to_hash[:user_name].should_not be_nil
                controller.to_hash[:password].should_not be_nil
            end

            it "should have applications" do
                controller.to_hash[:applications].should_not be_nil
            end
        end
    end

    describe :from_hash do
        let(:controller_hash) { JSON.parse(File.read("#{File.dirname(__FILE__)}/../fixtures/full_controller.json")) }

        it "should be a class method" do
            Appdynamics::Controller.respond_to?(:from_hash).should == true
        end

        it "should build a controller" do
            Appdynamics::Controller.from_hash(controller_hash).class.should == Appdynamics::Controller
        end

        it "should populate a controller's applications" do
            Appdynamics::Application.should_receive(:from_hash).at_least(:once)
            Appdynamics::Controller.from_hash(controller_hash)
        end
    end
end