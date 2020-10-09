require 'hive'
require 'json'
require 'bitcoin'
require 'net/http'
require 'digest/sha2'

module Beeline
  class Session
    include Config
    include Hive::Utils
    
    attr_reader :ws_session, :cookies
    
    def initialize
      @base_uri = nil
      @ws_uri = nil
      @cookies = nil
      @ws_session = nil
      @http = nil
    end
    
    def base_uri
      @base_uri ||= URI.parse(BEE_BASE_URL)
    end
    
    def ws_uri
      @ws_uri ||= URI.parse(BEE_WS_URL)
    end
    
    def tokens
      login if @cookies.nil?
      
      return if @cookies.nil?
      
      [
        @cookies.split('; ').select{|t| t.start_with? 'token='}.first,
        @cookies.split('; ').select{|t| t.start_with? 'refresh_token='}.first
      ].join('; ')
    end
    
    def ws_token
      login if @ws_session.nil?
      
      return if @ws_session.nil?
      
      @ws_session['ws_token']
    end
    
    def http(&block)
      Net::HTTP.start(base_uri.host, base_uri.port, use_ssl: base_uri.scheme == 'https') do |http|
        yield http
      end
    end
    
    def login
      return @ws_session if !!@ws_session
      
      timestamp = (Time.now.to_f * 1000).to_i
      message = "#{hive_account}#{timestamp}"
      signature = hexlify sign_message message
      resource = "#{base_uri.path}/users/login?username=#{hive_account}&ts=#{timestamp}&sig=#{signature}"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        response = http.request request
        
        if response.code == '200'
          @cookies = response['Set-Cookie']
          @ws_session = JSON[response.body]
        else
          JSON[response.body]
        end
      end
    end
    
    def verify
      raise "Unable to verify before logging in" unless !!@ws_session
      
      resource = "#{base_uri.path}/users/verify"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    def refresh_token
      raise "Unable to refresh token before logging in" unless !!@ws_session
      
      resource = "#{base_uri.path}/refresh-token"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        if response.code == '200'
          @cookies = response['Set-Cookie']
          @ws_session = JSON[response.body]
        else
          JSON[response.body]
        end
      end
    end
    
    def get(resource)
      raise "Unable to request #{resource} before logging in" unless !!@ws_session
      
      resource = "#{base_uri.path}#{resource}"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    def friends; get('/users/friends'); end
    def friend_requests; get('/users/friend-requests'); end
    def settings; get('/users/settings'); end
    
    def settings=(new_settings)
      raise "Unable to post settings before logging in" unless !!@ws_session
      
      resource = "#{base_uri.path}/users/settings"
      
      http do |http|
        request = Net::HTTP::Post.new resource
        request.body = new_settings.to_json
        request['Content-Type'] = 'application/json; charset=UTF-8'
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    def channels; get('/users/channels'); end
    
    def channels=(new_channels)
      raise "Unable to post channels before logging in" unless !!@ws_session
      
      resource = "#{base_uri.path}/users/channels"
      
      http do |http|
        request = Net::HTTP::Post.new resource
        request.body = new_channels.to_json
        request['Content-Type'] = 'application/json; charset=UTF-8'
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        JSON[response.body]
      end
    end

    def logout; get('/users/logout'); end
    def conversations; get('/messages/conversations'); end
    
    def conversation(*id)
      raise "Unable to get conversation before logging in" unless !!@ws_session
      
      id = [id].flatten
      resource = "#{base_uri.path}/messages/conversation?ids=#{id.join(',')}"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    def new_conversations; get('/messages/new'); end
    
    def chats(id, before = nil, limit = nil)
      raise "Unable to get conversation before logging in" unless !!@ws_session
      
      resource = "#{base_uri.path}/messages/chats?conversation_id=#{id}"
      resource += "&before=#{before.utc.iso8601}" if !!before
      resource += "&limit=#{limit}" if !!limit
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Cookie'] = tokens
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    def dump_conversations
      new_conversations.map{|c| "#{c['timestamp']} :: #{c['conversation_id']} :: #{c['from']}: #{c['content']}"}
    end
    
    def inspect
      properties = %w(base_uri ws_uri ws_session).map do |prop|
        if !!(v = instance_variable_get("@#{prop}"))
          case v
          when Array then "@#{prop}=<#{v.size} #{v.size == 1 ? 'element' : 'elements'}>" 
          else; "@#{prop}=#{v}" 
          end
        end
      end.compact.join(', ')
      
      "#<#{self.class} [#{properties}]>"
    end
  private
    # @private
    def sign_message(message)
      digest_hex = Digest::SHA256.digest(message)
      private_key = Bitcoin::Key.from_base58 hive_posting_wif
      public_key = Bitcoin.decode_base58(hive_public_key[3..-1])[0..65]
      
      Bitcoin::OpenSSL_EC.sign_compact(digest_hex, private_key.priv, public_key, true)
    end
  end
end
