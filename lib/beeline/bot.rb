module Beeline
  class Bot < Client
    attr_reader :prefix
    
    def command name, options = {}, &block
      commands[name] = {options: options, block: block}
    end
    
    def message pattern, options = {}, &block
      messages[pattern] = {options: options, block: block}
    end
    
    def process_status(payload)
      if payload['authenticated']
        puts 'Got acknowledge authenticated.'
      else
        abort 'Unable to authenticate.'
      end
    end
    
    def process_chat_message(payload)
      from = payload['from']
      
      cooldown(from)
      
      conversation_id = payload['conversation_id']
      content = payload['content'].to_s
      command_key = content.split(' ').first.split(prefix).last.to_sym
      reply = if commands.keys.include? command_key
        args = (content.split(' ') - ["#{prefix}#{command_key}"]).join(' ')
        args = args.empty? ? nil : args
        
        commands[command_key][:block].call(args, from, conversation_id)
      elsif (matching_messages = messages.select{|k| Regexp.new(k).match?(content)}).any?
        message = matching_messages.values.first # match in order of declaration
        
        message[:block].call(content, from, conversation_id)
      end
      
      if !!reply
        chat_message(conversation_id, from, reply)
      end
    end
    
    def process_friendship_requested(payload)
      return unless friendships[:accept] == 'auto'
      
      accept_pending_friend_requests
    end
  private
    MIN_COOLDOWN = 0.25
    BASE_COOLDOWN = 0.1
    MAX_COOLDOWN = 90.0
    
    # Exponential backoff for key.  This will apply a rate-limit for each key
    # that depends on how often the key is used.
    # 
    # @private
    def cooldown(key)
      @cooldown ||= {}
      @cooldown[key] ||= Time.now
      elapsed = Time.now - @cooldown[key]
      
      if elapsed > MAX_COOLDOWN
        @cooldown[key] = nil
      else
        interval = [BASE_COOLDOWN * elapsed, MIN_COOLDOWN].max
        
        sleep interval
      end
    end
  end
end
