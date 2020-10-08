require 'pry'

Bundler.require

defined? Thread.report_on_exception and Thread.report_on_exception = true

require 'beeline/config'
require 'beeline/client'
require 'beeline/session'
require 'beeline/bot'

module Beeline
  PWD = Dir.pwd.freeze
  BEE_BASE_URL = 'https://beechat.hive-engine.com/api'.freeze
  BEE_WS_URL = 'wss://ws.beechat.hive-engine.com'.freeze
  WS_KEEPALIVE_TIME = 30.freeze
  
  extend self
end
