require 'rspec'
require './lib/appdynamics'

describe Appdynamics::Application do
    context "with all nodes, tiers, and metrics populated" do
        let(:controller) { Appdynamics::Controller.deserialize(File.read("#{File.dirname(__FILE__)}/../fixtures/full_controller.yml")) }

        describe :to_hash do
            let(:application) { controller.applications.first }
            it "should be defined" do
                application.respond_to?(:to_hash).should == true
            end

            it "should have configuration fields" do
                application.to_hash[:application_name].should_not be_nil
                application.to_hash[:application_id].should_not be_nil
            end

            it "should have nodes" do
                application.to_hash[:nodes].should_not be_nil
            end

            it "should have tiers" do
                application.to_hash[:tiers].should_not be_nil
            end

            it "should have metrics" do
                application.to_hash[:metrics].should_not be_nil
            end
        end

        describe :from_hash do
            let(:application_hash) { JSON.parse(File.read("#{File.dirname(__FILE__)}/../fixtures/application.json")) }
            it "should be a class method" do
                Appdynamics::Application.respond_to?(:from_hash).should == true
            end
            it "should require 2 parameters" do
                expect { Appdynamics::Application.from_hash(application_hash) }.to raise_error
            end

            it "should build an application" do
                Appdynamics::Application.from_hash(application_hash, controller).class.should == Appdynamics::Application
            end

            it "should populate an application's nodes" do
                Appdynamics::Node.should_receive(:from_hash).at_least(:once)
                Appdynamics::Application.from_hash(application_hash, controller)
            end

            it "should populate an application's tiers" do
                Appdynamics::Tier.should_receive(:from_hash).at_least(:once)
                Appdynamics::Application.from_hash(application_hash, controller)
            end

            it "should populate an application's metrics" do
                Appdynamics::Metric.should_receive(:from_hash).at_least(:once)
                Appdynamics::Application.from_hash(application_hash, controller)
            end
        end
    end
end