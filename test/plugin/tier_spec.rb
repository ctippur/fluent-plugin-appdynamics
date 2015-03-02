require 'rspec'
require './lib/appdynamics'

describe Appdynamics::Tier do
    let(:controller) { Appdynamics::Controller.deserialize(File.read("#{File.dirname(__FILE__)}/../fixtures/full_controller.yml")) }
    let(:application) { controller.applications.first }
    let(:tier) { application.tiers.first }

    describe :to_hash do
        it "should be defined" do
            tier.respond_to?(:to_hash).should == true
        end

        it "should have identification parameters" do
            tier.to_hash[:id].should_not be_nil
            tier.to_hash[:agentType].should_not be_nil
            tier.to_hash[:description].should_not be_nil
            tier.to_hash[:name].should_not be_nil
            tier.to_hash[:numberOfNodes].should_not be_nil
            tier.to_hash[:type].should_not be_nil
        end

        it "should not have parents" do
            tier.to_hash[:controller].should be_nil
            tier.to_hash[:application].should be_nil
        end
    end

    describe :from_hash do
        let(:tier_hash) { JSON.parse(File.read("#{File.dirname(__FILE__)}/../fixtures/tier.json")) }
        it "should be a class method" do
            Appdynamics::Tier.respond_to?(:from_hash).should == true
        end

        it "should require 3 parameters" do
            expect { Appdynamics::Tier.from_hash(tier_hash) }.to raise_error
        end

        it "should return a single tier" do
            Appdynamics::Tier.from_hash(tier_hash, controller, application).class.should == Appdynamics::Tier
        end
    end
end