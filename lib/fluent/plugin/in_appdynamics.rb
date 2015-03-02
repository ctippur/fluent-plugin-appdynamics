module Fluent

# Read  trap messages as events in to fluentd
  class NewRelicInput < Input
    Fluent::Plugin.register_input('newrelic', self)

    # Define default configurations
    # Example: config_param :tag, :string, :default => "alert.newrelic"
    config_param :interval, :string, :default => "5"
    config_param :tag, :string, :default => "alert.appdynamics"
    config_param :endpoint, :string, :default => "https://intuitapm2.saas.appdynamics.com/controller/rest/applications/xxxx/problems/healthrule-violations?time-range-type=BETWEEN_TIMES&output=JSONJSON" # Optional
    config_param :interval, :integer, :default => '300' #Default 5 minutes
    config_param :user, :string, :default => "rest-user"
    config_param :pass, :string, :default => "AyDS-6q+XdP5S=G"
    config_param :include_raw, :string, :default => "false" #Include original object as raw
    config_param :attributes, :string, :default => "ALL" # fields to include, ALL for... well, ALL.
   
    # function to UTF8 encode
    def to_utf8(str)
      str = str.force_encoding('UTF-8')
      return str if str.valid_encoding?
      str.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '')
    end

    # Initialize and bring in dependencies
    def initialize
      super
      require 'json'
      require 'rest_client'
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
      $log.info "starting appdynamics poller, interval #{@interval}"
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
	alertStartTime = Engine.now.to_i - @interval.to_i 
	$log.info "appdynamics :: Polling alerts for time period: #{alertStartTime.to_i} - #{Engine.now.to_i}"
	# Post to Appdynamics and parse results  
        responsePost=endpoint.post @xml,:content_type => 'application/xml',:accept => 'application/json'
	body = JSON.parse(responsePost.body)
	pp body
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
