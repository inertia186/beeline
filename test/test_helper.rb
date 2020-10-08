$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# if ENV["HELL_ENABLED"]
  require 'minitest/benchmark'
  require 'simplecov'
  SimpleCov.start
  SimpleCov.merge_timeout 3600
# end

require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'
require 'yaml'
require 'securerandom'
require 'beeline'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

if ENV["HELL_ENABLED"]
  require "minitest/hell"
  
  class Minitest::Test
    # See: https://gist.github.com/chrisroos/b5da6c6a37ac8af5fe78
    parallelize_me! unless defined? WebMock
  end
else
  require "minitest/pride"
end

if defined? WebMock 
  allow = ['codeclimate.com:443']
  WebMock.disable_net_connect!(allow_localhost: false, allow: allow)
end

module Beeline
  module Config
    def yml
      {
        chain: {
          hive_account: 'social',
          hive_public_key: 'STM5ctejUsoZ9FwfCaVbNvWYYgNMBo9TVsHSE8wHrqAmNJi6sDctt',
          hive_posting_wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC',
          hive_api_url: 'https://api.openhive.network',
        }
      }
    end
  end
end

module Beeline
  class Account
    def self.yml
      {
        'hive' => {
          'cosgrove' => {
            'discord_ids' => [COSGROVE_DISCORD_ID]
          }
        }
      }
    end
  end
end

class Beeline::Test < MiniTest::Test
  # VCR_RECORD_MODE = (ENV['VCR_RECORD_MODE'] || 'once').to_sym
  VCR_RECORD_MODE = :new_episodes
  
  def bot
    return @bot if !!@bot
    
    options = {
      name: 'BeelineBot',
      log_mode: :debug,
      prefix: '$',
    }
    
    VCR.use_cassette('bot_session', record: VCR_RECORD_MODE) do
      @bot = Beeline::Bot.new(options).tap do |bot|
        # bot.ping
        bot.command(:help) do |topic|; "This is help" end
        bot.message('Ping!') { 'Pong!' }
      end
    end
  end
  
  def save filename, result
    f = File.open("#{File.dirname(__FILE__)}/support/#{filename}", 'w+')
    f.write(result)
    f.close
  end
end
