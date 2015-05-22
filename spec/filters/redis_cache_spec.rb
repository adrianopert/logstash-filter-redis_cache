# encoding: utf-8
require 'logstash/devutils/rspec/spec_helper'
require "logstash/filters/redis_cache"
require 'redis'

redis = Redis.new(:host => "127.0.0.1", :db => 1)
# fill the redis cache with known values
redis.set("192.168.1.10", "{\"host\":\"la numero diez\",\"usuario\":\"cesar diaz\"}")

describe LogStash::Filters::Redis_Cache do
  describe "Agregamos campos del cache" do
    config <<-CONFIG			
      filter {
        redis_cache {
          key => "ip"
					fields => ["usuario", "sin_cargar"]
        }
      }
    CONFIG

		sample("ip" => "192.168.1.10") do
			insist { subject["ip"] } == "192.168.1.10"
			insist { subject["usuario"] } == "cesar diaz"
			# field miss in cache
			insist { subject["sin_cargar"] }.nil?
			# existent field in cache, but not required in configuration
			insist { subject["host"] }.nil?
		end
		# cache miss
		sample("ip" => "192.168.1.x") do
			insist { subject["ip"] } == "192.168.1.x"
			insist { subject["usuario"] }.nil?
			insist { subject["sin_cargar"] }.nil?
			insist { subject["host"] }.nil?
		end
	end
end
