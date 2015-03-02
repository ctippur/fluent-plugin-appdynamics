require 'rspec'
require './lib/appdynamics'

describe Appdynamics::Metric do
    let(:controller) { Appdynamics::Controller.deserialize(File.read("#{File.dirname(__FILE__)}/../fixtures/full_controller.yml")) }
    let(:application) { controller.applications.first }

    describe :to_hash do
        let(:metric) { application.metrics.first }

        it "should be defined" do
            metric.respond_to?(:to_hash).should == true
        end

        it "should have type and name parameters" do
            metric.to_hash[:type].should_not be_nil
            metric.to_hash[:name].should_not be_nil
        end

        it "should have metrics" do
            metric.to_hash[:metrics].should_not be_nil
        end
    end

    describe :from_hash do
        it "should be a class method" do
            Appdynamics::Metric.respond_to?(:from_hash).should == true
        end

        it "should require 3 parameters" do
            expect { Appdynamics::Metric.from_hash(metric_hash) }.to raise_error
        end

        context :alone do
            let(:metric_hash) { JSON.parse(File.read("#{File.dirname(__FILE__)}/../fixtures/single_metric.json")) }

            it "should return a single metric" do
                Appdynamics::Metric.from_hash(metric_hash, controller, application).class.should == Appdynamics::Metric
            end

            it "should be of type 'leaf'" do
                Appdynamics::Metric.from_hash(metric_hash, controller, application).type.should == 'leaf'
            end
        end

        context :with_children do
            let(:metric_hash) { JSON.parse(File.read("#{File.dirname(__FILE__)}/../fixtures/metrics.json")) }

            it "should cause @metrics to be defined in the target metric" do
                metric = Appdynamics::Metric.from_hash(metric_hash, controller, application)
                metric.instance_variables.include?(:@metrics).should == true
                metric.metrics.first.name.should_not be_nil
            end
        end
    end
end