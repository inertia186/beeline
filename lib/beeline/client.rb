require 'faye/websocket'
require 'eventmachine'
require 'permessage_deflate'

module Beeline
  class Client
    include Beeline::Config
    
    attr_reader :commands, :messages
    
    INITIAL_LATCH = 0.01
    MAX_LATCH = 3.0
    
    def initialize(options = {})
      @session = options[:session]
      @url = options[:url] || BEE_WS_URL
      @commands = options[:commands] || {}
      @messages = options[:messages] || {}
      @prefix = options[:prefix] || '$'
      @latch = INITIAL_LATCH
      @socket = nil
      @thread_running = false
    end
    
    def reset_session
      @session = nil
    end
    
    def run(options = {async: false})
      async = !!options[:async]
      start_thread(async) unless !!@thread_running
      
      socket
    end
    
    def run_loop
      loop do
        start_thread(false) unless !!@thread_running
        
        sleep [@latch *= 2, MAX_LATCH].min
      end
    end
    
    def ping
      start = Time.now
      
      puts 'Ping ... '
      
      socket.ping('Ping!') do
        puts "Pong! (#{Time.now - start})"
      end
    end
  private
    def session
      @session ||= Session.new
    end
    
    def socket
      @socket ||= Faye::WebSocket::Client.new(BEE_WS_URL, [],
        extensions: [PermessageDeflate],
        headers: {
          'User-Agent' => AGENT_ID,
          'Cookie' => session.tokens
        },
        ping: WS_KEEPALIVE_TIME
      )
    end
    
    def authenticate
      if result = socket.send({type: 'authenticate', payload: {username: hive_account, token: session.ws_token}}.to_json)
        puts "Authentication sent: #{session.inspect}"
        
        ping
      else
        puts "Could not authenticate."
      end
    end
    
    def chat_message(conversation_id, to, message)
      socket.send({type: 'chat-message', payload: {conversation_id: conversation_id, to: to, message: message}}.to_json)
    end
    
    # @private
    def start_thread(async = false)
      thread = Thread.new do
        EM.run {
          socket.on :open do |event|
            p [:ws, [:open]]
            authenticate
            @thread_running = true
          end

          socket.on :message do |event|
            data = JSON[event.data] rescue nil
            
            if !!data && !!data['type'] && !!data['payload']
              payload = data['payload']
              
              case data['type']
              when 'status' then process_status(payload)
              when 'reauthentication-required' then session.refresh_token
              when 'chat-message' then process_chat_message(payload)
              when 'message-deleted' then process_message_deleted(payload)
              when 'conversation-created' then process_conversation_created(payload)
              when 'conversation-renamed' then process_conversation_renamed(payload)
              when 'conversation-removed' then process_conversation_removed(payload)
              when 'acknowledged' then process_acknowledged(payload)
              when 'member-added' then process_member_added(payload)
              when 'member-removed' then process_member_removed(payload)
              when 'moderator-added' then process_moderator_added(payload)
              when 'moderator-removed' then process_moderator_removed(payload)
              when 'friendship-accepted' then process_friendship_accepted(payload)
              when 'friendship-removed' then process_friendship_removed(payload)
              when 'friendship-requested' then process_friendship_requested(payload)
              when 'friendship-rejected' then process_friendship_rejected(payload)
              when 'user-blocked' then process_user_blocked(payload)
              when 'user-unblocked' then process_user_unblocked(payload)
              else
                p [:beechat_message, data['type'], data['payload']]
              end
            else
              p [:ws, [:message, event.data]]
            end
          end
          
          socket.on :close do |event|
            p [:ws, [:close, event.code, event.reason]]
            @thread_running = false
            @socket = nil
            EM.stop
          end
          
          socket.on :error do |event|
            p [:ws, [:error, event.message.inspect]]
            @thread_running = false
            @socket = nil
            EM.stop
          end
        }
      end
      
      thread.join unless !!async
    end
    
    # Override to procsss.
    def process_status(payload); end
    
    # Override to procsss.
    def process_chat_message(payload); end
    
    # Override to procsss.
    def process_message_deleted(payload); end
    
    # Override to procsss.
    def process_conversation_created(payload); end
    
    # Override to procsss.
    def process_conversation_renamed(payload); end
    
    # Override to procsss.
    def process_conversation_removed(payload); end
    
    # Override to procsss.
    def process_acknowledged(payload); end
    
    # Override to procsss.
    def process_member_added(payload); end
    
    # Override to procsss.
    def process_member_removed(payload); end
    
    # Override to procsss.
    def process_moderator_added(payload); end
    
    # Override to procsss.
    def process_moderator_removed(payload); end
    
    # Override to procsss.
    def process_friendship_accepted(payload); end
    
    # Override to procsss.
    def process_friendship_removed(payload); end
    
    # Override to procsss.
    def process_friendship_requested(payload); end
    
    # Override to procsss.
    def process_friendship_rejected(payload); end
    
    # Override to procsss.
    def process_user_blocked(payload); end
    
    # Override to procsss.
    def process_user_unblocked(payload); end
  end
end
