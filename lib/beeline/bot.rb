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
      content = payload['content'].to_s
      command_key = content.split(' ').first.split(prefix).last.to_sym
      reply = if commands.keys.include? command_key
        args = (content.split(' ') - ["#{prefix}#{command_key}"]).join(' ')
        args = args.empty? ? nil : args
        
        commands[command_key][:block].call(args, from)
      elsif (matching_messages = messages.select{|k| Regexp.new(k).match?(content)}).any?
        message = matching_messages.values.first # match in order of declaration
        
        message[:block].call(content, from)
      end
      
      if !!reply
        conversation_id = payload['conversation_id']
        
        chat_message(conversation_id, from, reply)
      end
    end
  end
end
