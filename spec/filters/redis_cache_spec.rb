require 'spec_helper'
require "logstash/filters/redis_cache"

describe LogStash::Filters::Redis_Cache do
  describe "Agregamos campos del cache" do
    let(:config) do <<-CONFIG
			
      filter {
        redis_cache {
          key => "ip"
					fields => ["usuario"]
        }
      }
    CONFIG
    end

#    sample("message" => "some text") do
#      expect(subject).to include("message")
#      expect(subject['message']).to eq('Hello World')
#    end
  end
end
