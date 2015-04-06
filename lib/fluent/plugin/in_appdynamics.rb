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

    config_param :state_type, :string, :default => nil
    config_param :state_file, :string, :default => nil
    config_param :select_limit, :time, :default => 10000


    # Timewatcher class to handle collio
    class TimerWatcher < Coolio::TimerWatcher
      def initialize(interval, repeat, &callback)
        @callback = callback
        super(interval, repeat)
      end # def initialize
      
      def on_timer
        @callback.call
      rescue
        $log.error $!.to_s
        $log.error_backtrace
      end # def on_timer
    end
  
    # Class statestore
    class StateStore
      def initialize(path,tag)
        require 'yaml'
        @path = path
        if File.exists?(@path)
          @data = YAML.load_file(@path)
          if @data == false || @data == []
            # this happens if an users created an empty file accidentally
            @data = {}
          elsif !@data.is_a?(Hash)
            raise "state_file on #{@path.inspect} is invalid"
          end
        else
          @data = {}
        end
      end

      def last_records(tag=nil)
	return @data[tag]
        #@data['last_records'] ||= {}
      end

      def update_records(time, tag=nil)
	@data[tag]=time
	pp  @data
        File.open(@path, 'w') {|f|
          f.write YAML.dump(@data)
        }
      end
    end

    # Class store in memory
    class MemoryStateStore
      def initialize
        @data = {}
      end
      
      def last_records(tag=nil)
        @data['last_records'] ||= {}
      end
      
      def update_records(time,tag=nil)
      end
    end

    # Class store in redis
    class RedisStateStore
      state_key = ""
      def initialize(path,tag)
        state_key=tag
	#redis_server = $appsettings['redis_server']
	#redis_port = $appsettings['redis_port']
	#redis_spectrum_key = $appsettings['redis_spectrum_key']
	#####
      	require 'redis'
	$redis = if File.exists?(path)
		redis_config = YAML.load_file(path)
		# Connect to Redis using the redis_config host and port
		if path
		    begin
		        pp "In redis #{path} Host #{redis_config['host']} port #{redis_config['port']}"
  			$redis = Redis.new(host: redis_config['host'], port: redis_config['port'])
		    rescue Exception => e
			$log.info e.message
                	$log.info e.backtrace.inspect
		    end
		end
	else
  		Redis.new
	end
        @data = {}
      end
      
      def last_records(tag=nil)
        begin
  	   alertStart=$redis.get(tag)
           return alertStart
        rescue Exception => e
	   $log.info e.message
	   $log.info e.backtrace.inspect
        end
      end
      
      def update_records(time, tag=nil)
        begin
  	   alertStart=$redis.set(tag,time)
        rescue Exception => e
	   $log.info e.message
	   $log.info e.backtrace.inspect
        end
      end
    end

 
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
      require 'yaml'
      require 'rest-client'
      require 'pp'
      # Add any other dependencies
    end # def initialize

    # Load internal and external configs
    def configure(conf)
      super
      @conf = conf
      
      # State type is a must
      unless @state_type
        $log.warn "'state_type <redis/file/memory>' parameter is not set to a valid source."
        $log.warn "this parameter is highly recommended to save the last known good timestamp to resume event consuming"
	exit
      end

      # Define a handler that gets filled with 
      unless @state_file
           $log.warn "'state_file PATH' parameter is not set to a valid source."
           log.warn "this parameter is highly recommended to save the last known good timestamp to resume event consuming"
	   @state_store = MemoryStateStore.new
	else
	   if (@state_type =~ /redis/)
	   	@state_store = RedisStateStore.new(@state_file, @tag)
	   elsif (@state_type =~ /file/)
		@state_store = StateStore.new(@state_file, @tag)
	   else
		$log.warn "Unknown state type. Need to handle this better"
		exit
	   end
      end

      
      #@state_store = @state_file.nil? ? MemoryStateStore.new : StateStore.new(@state_file)

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
      @stop_flag = false
      @loop = Coolio::Loop.new
      #timer_trigger = TimerWatcher.new(@interval, true, &method(:input))
      #timer_trigger.attach(@loop)
      @loop.attach(TimerWatcher.new(@interval, true, &method(:input)))
      @thread = Thread.new(&method(:run))
      $log.info "starting appdynamics poller, interval #{@interval}"
    end

    # Stop Listener and cleanup any open connections.
    def shutdown
      super
      @stop_flag = true
      @loop.stop
      @thread.join
    end

    def run
      @loop.run
      $log.info "Running appdynamics Input"
    rescue
      $log.error "unexpected error", :error=>$!.to_s
      $log.error_backtrace
    end

    # Start appdynamics Trap listener
    # Add the code to run this
    def input
      if not @stop_flag
	alertEnd = Engine.now.to_i * 1000
	#alertStart = (Engine.now.to_f * 1000).to_i - @interval.to_i 
	#alertStart = Engine.now.to_i * 1000 
        if @state_store.last_records(@tag) 
          alertStart = @state_store.last_records(@tag)
          $log.info @tag + " :: Got time record from state_store - #{alertStart}" 
        else
          alertStart = pollingStart.to_i - @interval.to_i
          #$log.info "Spectrum :: Got time record from initial config - #{alertStart}"
        end
        
	$log.info "appdynamics :: Polling alerts for time period: #{alertStart.to_i} - #{alertEnd.to_i}"
	# Post to Appdynamics and parse results  

	begin
        	responsePost=appdynamicsEnd(alertStart,alertEnd).get
		#@state_store.update(pollingEnd, @tag)
		pollingDuration = alertEnd - alertStart
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
		val["event_type"] = @tag.to_s
		val["receive_time_input"]=(Engine.now * 1000).to_s
		#puts "#{val} => #{index}" 
		$log.info val
		begin
          		Engine.emit(@tag, val['startTimeInMillis'].to_i,val)
			#@state_store.update
		rescue Exception => e
			$log.info e.message
			$log.info e.backtrace.inspect
		end
	}
	#pp body.class
	@state_store.update_records(alertEnd, @tag)
      end # END Stop flag
    end # def Input

  end # End Input class

end # module Fluent
