require 'yaml'

module Beeline
  module Config
    def hive_account
      chain[:hive_account]
    end
    
    def hive_posting_wif
      chain[:hive_posting_wif]
    end
    
    def hive_public_key
      chain[:hive_public_key]
    end
  private
    def chain
      @chain_hash ||= yml[:chain]
    end
    
    def yml
      return @yml if !!@yml
      
      config_yaml_path = "#{Beeline::PWD}/config.yml"
      
      @yml = if File.exist?(config_yaml_path)
        YAML.load_file(config_yaml_path)
      else
        raise "Create a file: #{config_yaml_path}"
      end
      
      @yml
    end
  end
end
