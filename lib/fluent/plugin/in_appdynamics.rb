module Fluent

# Read  trap messages as events in to fluentd
  class AppdynamicsInput < Input
    Fluent::Plugin.register_input('appdynamics', self)

    # Define default configurations
    # Example: config_param :tag, :string, :default => "alert.newrelic"
    config_param :tag, :string, :default => "alert.appdynamics"
    config_param :endpoint, :string, :default => "" # Optional
    config_param :interval, :integer, :default => '300' #Default 5 minutes
    config_param :user, :string, :default => ""
    config_param :pass, :string, :default => ""
    config_param :account, :string, :default => ""
    config_param :include_raw, :string, :default => "true" #Include original object as raw
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
      require 'rest-client'
      require 'pp'
      # Add any other dependencies
    end # def initialize

    # Load internal and external configs
    def configure(conf)
      super
      @conf = conf
      def appdynamicsEnd(startTime,endTime)
      	# Setup URL Resource
	# Sample https://ep/controller/rest/applications/Prod/problems/healthrule-violations?time-range-type=BETWEEN_TIMES&output=JSON&start-time=1426270552990&end-time=1426270553000
	@url = @endpoint.to_s + "problems/healthrule-violations?time-range-type=BETWEEN_TIMES&output=JSON" + "&start-time=" + startTime.to_s + "&end-time=" + endTime.to_s
	$log.info @url
        RestClient::Resource.new(@url,@user+"@"+@account,@pass)
      end
      def appdynamicsEntEnd(entityId)
		# Setup URL Resource
		# Sample https://ep/controller/rest/applications/Prod/nodes/81376?output=JSON
		@urlEntity = @endpoint.to_s + "nodes/" + entityId.to_s + "?output=JSON"
		$log.info @urlEntity
		RestClient::Resource.new(@urlEntity,@user+"@"+@account,@pass)
      end
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
      $log.info "Running appdynamics Input"
    end

    # Start appdynamics Trap listener
    # Add the code to run this
    def input
	alertStartTime = (Engine.now.to_f * 1000).to_i - @interval.to_i 
	$log.info "appdynamics :: Polling alerts for time period: #{alertStartTime.to_i} - #{(Engine.now.to_f * 1000).to_i}"
	# Post to Appdynamics and parse results  

	begin
        	responsePost=appdynamicsEnd(alertStartTime,(Engine.now.to_f * 1000).to_i).get
	rescue Exception => e
		$log.info e.message
		$log.info e.backtrace.inspect
	end
	# body is an array of hashes
	body = JSON.parse(responsePost.body)
	body.each_with_index {|val, index| 
		#pp val
		$log.debug val
		if @include_raw.to_s == "true"  
			# Deep copy
			rawObj=val.clone
        		#val << { "raw" => "#rawObj" }
			val["raw"]=rawObj
        	end
		# Need to do another call to get the hostname
		if ((val["affectedEntityDefinition"] || {})["entityId"] != nil) then
			begin
        			responsePostAffEnt=appdynamicsEntEnd(val["affectedEntityDefinition"]["entityId"]).get
				bodyAffEntity = JSON.parse(responsePostAffEnt.body)
				val["AffectedEntityName"]=bodyAffEntity[0]["name"]
				
			rescue Exception => e
				$log.info e.message
				$log.info e.backtrace.inspect
				val["TrigerredEntityName"]=""
			end
			#pp bodyAffEntity["name"]
			#val["AffectedEntityName"]=bodyAffEntity["name"]

		end
		if ((val["triggeredEntityDefinition"] || {})["entityId"] != nil) then
			begin
        			responsePostTrigEnt=appdynamicsEntEnd(val["triggeredEntityDefinition"]["entityId"]).get
				bodyTrigEnt = JSON.parse(responsePostTrigEnt.body)
				val["TrigerredEntityName"]=bodyTrigEnt[0]["name"]
			rescue Exception => e
				$log.info e.message
				$log.info e.backtrace.inspect
				val["TrigerredEntityName"]=""
			end
			#val["TrigerredEntityName"]=bodyTrigEnt["name"]
		end
		#puts "#{val} => #{index}" 
		$log.info val
          	Engine.emit(@tag, val['startTimeInMillis'].to_i,val)
	}
	#pp body.class
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
