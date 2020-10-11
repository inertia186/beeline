require 'hive'
require 'json'
require 'bitcoin'
require 'net/http'
require 'digest/sha2'

module Beeline
  
  # Manages the http and websockets session for the bot.  Also interacts with
  # the http API.
  class Session
    include Config
    include Hive::Utils
    
    attr_reader :ws_session
    
    def initialize
      @base_uri = nil
      @ws_uri = nil
      @beeline_session = nil
      @http = nil
    end
    
    def base_uri
      @base_uri ||= URI.parse(BEE_BASE_URL)
    end
    
    def ws_uri
      @ws_uri ||= URI.parse(BEE_WS_URL)
    end
    
    def token
      login if @beeline_session.nil?
      
      return if @beeline_session.nil?
      
      @beeline_session['token']
    end
    
    def http(&block)
      Net::HTTP.start(base_uri.host, base_uri.port, use_ssl: base_uri.scheme == 'https') do |http|
        yield http
      end
    end
    
    # Logs in the bot.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-userslogin GET /users/login}
    def login
      return @beeline_session if !!@beeline_session
      
      timestamp = (Time.now.to_f * 1000).to_i
      message = "#{hive_account}#{timestamp}"
      signature = hexlify sign_message message
      resource = "#{base_uri.path}/users/login?username=#{hive_account}&ts=#{timestamp}&sig=#{signature}"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        response = http.request request
        
        if response.code == '200'
          @beeline_session = JSON[response.body]
        else
          JSON[response.body]
        end
      end
    end
    
    # Verifies if the current access token is valid.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-usersverify GET /users/verify}
    def verify
      raise "Unable to verify before logging in" unless !!@beeline_session
      
      resource = "#{base_uri.path}/users/verify"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{token}"
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    # Requests a new access token.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-usersrefresh-token GET /users/refresh-token}
    def refresh_token
      raise "Unable to refresh token before logging in" unless !!@beeline_session
      
      resource = "#{base_uri.path}/refresh-token"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{@beeline_session['refresh_token']}"
        response = http.request request
        
        if response.code == '200'
          @beeline_session['token'] = JSON[response.body]['token']
        else
          JSON[response.body]
        end
      end
    end
    
    # Generalized get method.
    # 
    # @param resource [String] Resource to get, including query parameters.
    def get(resource)
      raise "Unable to request #{resource} before logging in" unless !!@beeline_session
      
      resource = "#{base_uri.path}#{resource}"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{token}"
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    # Returns bot's friends and blocked list.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-usersfriends GET /users/friends}
    def friends; get('/users/friends'); end
    
    # Returns an array of bot's pending friend requests.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-usersfriend-requests GET /users/friend-requests}
    def friend_requests; get('/users/friend-requests'); end
    
    # Returns bot's settings.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-userssettings GET /users/settings}
    def settings; get('/users/settings'); end
    
    # Updates the bot's settings.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#post-userssettings POST /users/settings}
    # 
    # @param new_settings [Hash]
    # @option new_settings [Hash] :dm
    #   * :only_from_friends (Boolean) Only allow direct messages from friends.
    def settings=(new_settings)
      raise "Unable to post settings before logging in" unless !!@beeline_session
      
      resource = "#{base_uri.path}/users/settings"
      
      http do |http|
        request = Net::HTTP::Post.new resource
        request.body = new_settings.to_json
        request['Content-Type'] = 'application/json; charset=UTF-8'
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{token}"
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    # Returns an array of bot-created channels.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-userschannels GET /users/channels}
    def channels; get('/users/channels'); end
    
    # Creates a new channel.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#post-userschannels POST /users/channels}
    # 
    # @param name [String]
    def channels=(name)
      raise "Unable to post channels before logging in" unless !!@beeline_session
      
      resource = "#{base_uri.path}/users/channels"
      
      http do |http|
        request = Net::HTTP::Post.new resource
        request.body = name
        request['Content-Type'] = 'application/json; charset=UTF-8'
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{token}"
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    # Logs out the bot.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-userslogout GET /users/logout}
    def logout; get('/users/logout'); end
    
    # Returns details of a conversation.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-messagesconversation GET /messages/conversation}
    def conversations; get('/messages/conversations'); end
    
    # Returns details of a conversation.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-messagesconversation GET /messages/conversation}
    # 
    # @param id [String] (or Array<String>) Conversation id or array of ids.
    def conversation(*id)
      raise "Unable to get conversation before logging in" unless !!@beeline_session
      
      id = [id].flatten
      resource = "#{base_uri.path}/messages/conversation?ids=#{id.join(',')}"
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{token}"
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    # Return an array of unread messages.
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-messagesnew GET /messages/new}
    def new_conversations; get('/messages/new'); end
    
    # Query chat messages by id, \
    # 
    # See: {https://github.com/hive-engine/beechat-frontend/blob/master/DOCUMENTATION.md#get-messageschats GET /messages/chats}
    def chats(id, before = nil, limit = nil)
      raise "Unable to get conversation before logging in" unless !!@beeline_session
      
      resource = "#{base_uri.path}/messages/chats?conversation_id=#{id}"
      resource += "&before=#{before.utc.iso8601}" if !!before
      resource += "&limit=#{limit}" if !!limit
      
      http do |http|
        request = Net::HTTP::Get.new resource
        request['User-Agent'] = AGENT_ID
        request['Authorization'] = "Bearer #{token}"
        response = http.request request
        
        JSON[response.body]
      end
    end
    
    # Calls #new_conversations and dumps all messages.
    # 
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
