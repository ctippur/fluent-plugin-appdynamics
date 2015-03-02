module Fluent

# Read  trap messages as events in to fluentd
  class NewRelicInput < Input
    Fluent::Plugin.register_input('newrelic', self)

    # Define default configurations
    # Example: config_param :tag, :string, :default => "alert.newrelic"
    config_param :interval, :string, :default => "5"
    config_param :tag, :string, :default => "alert.appdynamics"
    config_param :endpoint, :string, :default => "" # Optional
   


    # Initialize and bring in dependencies
    def initialize
      super
      require 'json'
      require 'daemons'
      require 'pp'
      # Add any other dependencies
    end # def initialize

    # Load internal and external configs
    def configure(conf)
      super
      @conf = conf
      # TO DO Add code to choke if config parameters are not there
    end # def configure
    
    def start
      super
      @loop = Coolio::Loop.new
      timer_trigger = TimerWatcher.new(@interval, true, &method(:input))
      timer_trigger.attach(@loop)
      @thread = Thread.new(&method(:run))
      .info "starting appdynamics poller, interval #{@interval}"
    end

    # Stop Listener and cleanup any open connections.
    def shutdown
      super
      @loop.stop
      @thread.join
    end

    def run
      @loop.run
      .info "Running appdynamics Input"
    end

    # Start appdynamics Trap listener
    # Add the code to run this
    def input
    end # def Input

  end # End Input class

  class TimerWatcher < Coolio::TimerWatcher
	def initialize(interval, repeat, &callback)
	  @callback = callback
	  super(interval, repeat)
	end

	def on_timer
	  @callback.call
	end
  end

end # module Fluent
