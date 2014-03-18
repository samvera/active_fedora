require 'erb'
require 'yaml'

module ActiveFedora
  class FileConfigurator

    # Initializes ActiveFedora's connection to Fedora and Solr based on the info in fedora.yml and solr.yml
    # NOTE: this deprecates the use of a solr url in the fedora.yml
    #
    # 
    # If Rails.env is set, it will use that environment.  Defaults to "development".
    # @param [Hash] options (optional) a list of options for the configuration of active_fedora
    # @option options [String] :environment The environment within which to run
    # @option options [String] :fedora_config_path The full path to the fedora.yml config file.
    # @option options [String] :solr_config_path The full path to the solr.yml config file.
    # 
    # If :environment is not set, order of preference is 
    # 1. Rails.env
    # 2. ENV['environment']
    # 3. RAILS_ENV
    #
    # If :fedora_config_path is not set, it will look in 
    # 1. +Rails.root+/config
    # 2. +current working directory+/config
    # 3. (default) the fedora.yml shipped with gem
    #
    # If :solr_config_path is not set, it will 
    # 1. look in config_options[:fedora_config_path].  If it finds a solr.yml there, it will use it.
    # 2. If it does not find a solr.yml and the fedora.yml contains a solr url, it will raise an configuration error 
    # 3. If it does not find a solr.yml and the fedora.yml does not contain a solr url, it will look in: +Rails.root+/config, +current working directory+/config, then the solr.yml shipped with gem

    # Options allowed in fedora.yml
    # first level is the environment (e.g. development, test, production and any custom environments you may have) 
    # the second level has these keys:
    # 1. url: url including protocol, host, port and path (e.g. http://127.0.0.1:8983/fedora)
    # 2. user: username
    # 3. password: password
    # 4. validateChecksum:  indicates to the fedora server whether you want to validate checksums when the datastreams are queried.  
    #
    # @example If you want to shard the fedora instance, you can specify an array of credentials. 
    #   production:
    #   - user: user1
    #     password: password1
    #     url: http://127.0.0.1:8983/fedora1
    #   - user: user2
    #     password: password2
    #     url: http://127.0.0.1:8983/fedora2
    #

    attr_accessor :config_env
    attr_reader :config_options, :fedora_config_path, :solr_config_path, :predicate_mappings_config_path

    # The configuration hash that gets used by RSolr.connect
    def initialize
      reset!
    end

    def init options = {}
      if options.is_a?(String) 
        raise ArgumentError, "Calling ActiveFedora.init with a path as an argument has been removed.  Use ActiveFedora.init(:fedora_config_path=>#{options})"
      end
      reset!
      @config_options = options
      load_configs
    end

    def fedora_config
      load_configs
      @fedora_config
    end
    def solr_config
      load_configs
      @solr_config
    end

    def path
      get_config_path(:fedora)
    end
    
    def reset!
      @config_loaded = false  #Force reload of configs
      @fedora_config = {}
      @solr_config = {}
      @config_options = {}
      @predicate_config_path = nil
    end

    def config_loaded?
      @config_loaded || false
    end

    def load_configs
      return if config_loaded?
      @config_env = ActiveFedora.environment
      
      load_fedora_config
      load_solr_config
      @config_loaded = true
    end

    def load_fedora_config
      return @fedora_config unless @fedora_config.empty?
      @fedora_config_path = get_config_path(:fedora)
      logger.info("ActiveFedora: loading fedora config from #{File.expand_path(@fedora_config_path)}")

      begin
        config_erb = ERB.new(IO.read(@fedora_config_path)).result(binding)
      rescue Exception => e
        raise("fedora.yml was found, but could not be parsed with ERB. \n#{$!.inspect}")
      end

      begin
        fedora_yml = YAML.load(config_erb)
      rescue Psych::SyntaxError => e
        raise "fedora.yml was found, but could not be parsed. " \
              "Error #{e.message}"
      end

      config = fedora_yml.symbolize_keys

      cfg = config[ActiveFedora.environment.to_sym] || {}
      @fedora_config = cfg.kind_of?(Array) ? cfg.map(&:symbolize_keys) : cfg.symbolize_keys
    end

    def load_solr_config
      return @solr_config unless @solr_config.empty?
      @solr_config_path = get_config_path(:solr)

      logger.info("ActiveFedora: loading solr config from #{File.expand_path(@solr_config_path)}")
      begin
        config_erb = ERB.new(IO.read(@solr_config_path)).result(binding)
      rescue Exception => e
        raise("solr.yml was found, but could not be parsed with ERB. \n#{$!.inspect}")
      end

      begin
        solr_yml = YAML.load(config_erb)
      rescue StandardError => e
        raise("solr.yml was found, but could not be parsed.\n")
      end

      config = solr_yml.symbolize_keys
      raise "The #{ActiveFedora.environment.to_sym} environment settings were not found in the solr.yml config.  If you already have a solr.yml file defined, make sure it defines settings for the #{ActiveFedora.environment.to_sym} environment" unless config[ActiveFedora.environment.to_sym]
      @solr_config = {:url=> get_solr_url(config[ActiveFedora.environment.to_sym].symbolize_keys)}
    end

    # Given the solr_config that's been loaded for this environment, 
    # determine which solr url to use
    def get_solr_url(solr_config)
      if @index_full_text == true && solr_config.has_key?(:fulltext) && solr_config[:fulltext].has_key?('url')
        return solr_config[:fulltext]['url']
      elsif solr_config.has_key?(:default) && solr_config[:default].has_key?('url')
        return solr_config[:default]['url']
      elsif solr_config.has_key?('url')
        return solr_config['url']
      elsif solr_config.has_key?(:url)
        return solr_config[:url]
      else
        raise URI::InvalidURIError
      end
    end
      
    # Determine the fedora config file to use. Order of preference is:
    # 1. Use the config_options[:config_path] if it exists
    # 2. Look in +Rails.root+/config/fedora.yml
    # 3. Look in +current working directory+/config/fedora.yml
    # 4. Load the default config that ships with this gem
    # @param [String] config_type Either ‘fedora’ or ‘solr’
    # @return [String]
    def get_config_path(config_type)
      config_type = config_type.to_s
      if (config_path = config_options.fetch("#{config_type}_config_path".to_sym,nil) )
        raise ConfigurationError, "file does not exist #{config_path}" unless File.file? config_path
        return File.expand_path(config_path)
      end
    
      # if solr, attempt to use path where fedora.yml is first
      if config_type == "solr" && (config_path = check_fedora_path_for_solr)
        return config_path
      end

      if defined?(Rails.root)
        config_path = "#{Rails.root}/config/#{config_type}.yml"
        return config_path if File.file? config_path
      end
    
      if File.file? "#{Dir.getwd}/config/#{config_type}.yml"  
        return "#{Dir.getwd}/config/#{config_type}.yml"
      end
    
      # Last choice, check for the default config file
      config_path = File.join(ActiveFedora.root, "config", "#{config_type}.yml")
      if File.file? config_path
        logger.warn "Using the default #{config_type}.yml that comes with active-fedora.  If you want to override this, pass the path to #{config_type}.yml to ActiveFedora - ie. ActiveFedora.init(:#{config_type}_config_path => '/path/to/#{config_type}.yml') - or set Rails.root and put #{config_type}.yml into \#{Rails.root}/config."
        return config_path
      else
        raise ConfigurationError, "Couldn't load #{config_type} config file!"
      end
    end
  
    # Checks the existing fedora_config.path to see if there is a solr.yml there
    def check_fedora_path_for_solr
      path = File.dirname(self.path) + "/solr.yml"
      if File.file? path
        return path
      else
        return nil
      end
    end

    def predicate_config
      @predicate_config_path ||= build_predicate_config_path
      YAML.load(File.open(@predicate_config_path)) if File.exist?(@predicate_config_path)
    end

    protected

    def build_predicate_config_path
      testfile = File.expand_path(get_config_path(:predicate_mappings))
      if File.exist?(testfile) && valid_predicate_mapping?(testfile)
        return testfile
      end
      raise PredicateMappingsNotFoundError
    end

    def valid_predicate_mapping?(testfile)
      mapping = YAML.load(File.open(testfile))
      return false unless mapping.has_key?(:default_namespace) && mapping[:default_namespace].is_a?(String)
      return false unless mapping.has_key?(:predicate_mapping) && mapping[:predicate_mapping].is_a?(Hash)
      true
    end

  end
end
