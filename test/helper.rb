require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  .puts e.message
  .puts "Run There was a NameError while loading fluent-plugin-appdynamics.gemspec: 
uninitialized constant README from
  /Users/ctippur/fluent-plugin-appdynamics/fluent-plugin-appdynamics.gemspec:15:in `block in <main>' to install missing gems"
  exit e.status_code
end
require 'test/unit'

.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
.unshift(File.dirname(__FILE__))
require 'fluent/test'
unless ENV.has_key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval {|obj|
    def method_missing(method, *args)
      # pass
    end
  }
   = nulllogger
end

require 'fluent/plugin/in_appdynamics'

class Test::Unit::TestCase
end
