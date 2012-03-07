require "loggable"
require 'active_support'
require 'active_fedora/solr_service'
require 'active_fedora/rubydora_connection'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object'
require 'active_support/core_ext/hash/indifferent_access'

SOLR_DOCUMENT_ID = ActiveFedora::SolrService.id_field unless defined?(SOLR_DOCUMENT_ID)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)

module ActiveFedora #:nodoc:
  extend ActiveSupport::Autoload

  class ObjectNotFoundError < RuntimeError; end # :nodoc:
  class PredicateMappingsNotFoundError < RuntimeError; end # :nodoc:
  class UnknownAttributeError < NoMethodError; end; # :nodoc:
  class ConfigurationError < RuntimeError; end # :nodoc:
  class AssociationTypeMismatch < RuntimeError; end # :nodoc:
  class UnregisteredPredicateError < RuntimeError; end # :nodoc:


  eager_autoload do
    autoload :Associations
    autoload :AttributeMethods
    autoload :Base
    autoload :ContentModel
    autoload :Callbacks
    autoload :Config
    autoload :Reflection
    autoload :Relationships
    autoload :FileManagement
    autoload :RelationshipGraph
    autoload :Datastream
    autoload :Datastreams
    autoload :Delegating
    autoload :DigitalObject
    autoload :UnsavedDigitalObject
    autoload :SolrDigitalObject
    autoload :Model
    autoload :MetadataDatastream
    autoload :MetadataDatastreamHelper
    autoload :NokogiriDatastream
    autoload :NtriplesRDFDatastream
    autoload :Property
    autoload :Persistence
    autoload :QualifiedDublinCoreDatastream
    autoload :RDFDatastream
    autoload :RelsExtDatastream
    autoload :ServiceDefinitions
    autoload :SemanticNode
    autoload :NestedAttributes
    autoload :FixtureLoader
    autoload :FixtureExporter
    autoload :DatastreamCollections
    autoload :NamedRelationships
    autoload :Predicates
    autoload :Validations

  end
  
  
  include Loggable
  
  class << self
    attr_accessor :solr_config, :fedora_config, :config_env, :solr_config_path
    attr_reader :config_options
  end
  
  # The configuration hash that gets used by RSolr.connect
  @solr_config ||= {}
  @fedora_config ||= {}
  @config_options ||= {}

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

  def self.init( options={} )
    # Make config_options into a Hash if nil is passed in as the value
    options = {} if options.nil?

    # For backwards compatibility, handle cases where config_path (a String) is passed in as the argument rather than a config_options hash
    # In all other cases, set config_path to config_options[:config_path], which is ok if it's nil
    if options.is_a? String
      raise ArgumentError, "Calling ActiveFedora.init with a path as an argument has been removed.  Use ActiveFedora.init(:fedora_config_path=>#{options})"
    else
      @config_options = options
    end
    config_reload!
  end

  def self.config_reload!
    reset!
    load_configs
  end

  def self.config
    load_configs
    @fedora_config
  end

  def self.reset!
    @config_loaded = false  #Force reload of configs
    @predicate_config_path = nil
  end

  def self.config_loaded?
    @config_loaded || false
  end

  def self.load_configs
    return if config_loaded?
    @config_env = environment
    @fedora_config = Config.new(get_config_path(:fedora), @config_env)
    load_config(:solr)
    @config_loaded = true

  end

  def self.load_config(config_type)
    config_path = get_config_path(config_type)
    config_type = config_type.to_s
    self.instance_variable_set "@#{config_type}_config_path".to_sym, config_path
    config_path = self.send("#{config_type}_config_path".to_sym)

    logger.info("#{config_type.upcase}: loading ActiveFedora.#{config_type}_config from #{File.expand_path(config_path)}")
    config = YAML.load(File.open(config_path)).symbolize_keys
    raise "The #{@config_env.to_sym} environment settings were not found in the #{config_type}.yml config.  If you already have a #{config_type}.yml file defined, make sure it defines settings for the #{@config_env} environment" unless config[@config_env.to_sym]
    
    config[:url] = determine_url(config_type,config)

    self.instance_variable_set("@#{config_type}_config", config)
    config
  end

  def self.config_for_environment
    ActiveSupport::Deprecation.warn("config_for_environment has been deprecated use `config' instead")
    config
  end

  # Determines and sets the fedora_config[:url] or solr_config[:url]
  # @param [String] config_type Either 'fedora' or 'solr'
  # @param [Hash] config The config hash 
  # @return [String] the solr or fedora url
  def self.determine_url(config_type,config)  
    c = config[environment.to_sym]
    c.symbolize_keys!
    if config_type == "fedora"
      url =  c[:url]
      if url && !c[:user]
        u = URI.parse url
        c[:user] = u.user
        c[:password] = u.password
        c[:url] = "#{u.scheme}://#{u.host}:#{u.port}#{u.path}"
        url = c[:url]
      end
      return url
    else
      return get_solr_url(c) if config_type == "solr"
    end
  end

  # Given the solr_config that's been loaded for this environment, 
  # determine which solr url to use
  def self.get_solr_url(solr_config)
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

  # Determine what environment we're running in. Order of preference is:
  # 1. config_options[:environment]
  # 2. Rails.env
  # 3. ENV['environment']
  # 4. ENV['RAILS_ENV']
  # 5. development
  # @return [String]
  # @example 
  #  ActiveFedora.init(:environment=>"test")
  #  ActiveFedora.environment => "test"
  def self.environment
    if config_options.fetch(:environment,nil)
      return config_options[:environment]
    elsif defined?(Rails.env) and !Rails.env.nil?
      return Rails.env.to_s
    elsif defined?(ENV['environment']) and !(ENV['environment'].nil?)
      return ENV['environment']
    elsif defined?(ENV['RAILS_ENV']) and !(ENV['RAILS_ENV'].nil?)
      logger.warn("You're depending on RAILS_ENV for setting your environment. This is deprecated in Rails3. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'")
      ENV['environment'] = ENV['RAILS_ENV']
      return ENV['environment']
    else
      ENV['environment'] = 'development' #raise "Can't determine what environment to run in!"
    end
  end
  
  # Determine the fedora config file to use. Order of preference is:
  # 1. Use the config_options[:config_path] if it exists
  # 2. Look in +Rails.root+/config/fedora.yml
  # 3. Look in +current working directory+/config/fedora.yml
  # 4. Load the default config that ships with this gem
  # @param [String] config_type Either ‘fedora’ or ‘solr’
  # @return [String]
  def self.get_config_path(config_type)
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
    config_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "config", "#{config_type}.yml"))
    logger.warn "Using the default #{config_type}.yml that comes with active-fedora.  If you want to override this, pass the path to #{config_type}.yml to ActiveFedora - ie. ActiveFedora.init(:#{config_type}_config_path => '/path/to/#{config_type}.yml) - or set Rails.root and put #{config_type}.yml into \#{Rails.root}/config."
    return config_path if File.file? config_path
    raise ConfigurationError "Couldn't load #{config_type} config file!"
  end
  
  # Checks the existing fedora_config.path to see if there is a solr.yml there
  def self.check_fedora_path_for_solr
    path = @fedora_config.path.split('/')[0..-2].join('/') + "/solr.yml"
    if File.file? path
      return path
    else
      return nil
    end
  end

  def self.solr
    ActiveFedora::SolrService.instance
  end
  
  
  def self.fedora
    ActiveSupport::Deprecation.warn("ActiveFedora.fedora() is deprecated and will be removed in the next release use ActiveFedora::Base.connection_for_pid(pid) instead")
    
    ActiveFedora::Base.connection_for_pid('0')
  end

  def self.predicate_config
    @predicate_config_path ||= build_predicate_config_path(File.dirname(@fedora_config.path))
  end

  def self.version
    ActiveFedora::VERSION
  end

  protected

  def self.build_predicate_config_path(config_path=nil)
    pred_config_paths = [File.expand_path(File.join(File.dirname(__FILE__),"..","config"))]
    pred_config_paths.unshift config_path if config_path
    pred_config_paths.each do |path|
      testfile = File.expand_path(File.join(path,"predicate_mappings.yml"))
      if File.exist?(testfile) && valid_predicate_mapping?(testfile)
        return testfile
      end
    end
    raise PredicateMappingsNotFoundError #"Could not find predicate_mappings.yml in these locations: #{pred_config_paths.join("; ")}." unless @predicate_config_path
  end

  def self.valid_predicate_mapping?(testfile)
    mapping = YAML::load(File.open(testfile))
    return false unless mapping.has_key?(:default_namespace) && mapping[:default_namespace].is_a?(String)
    return false unless mapping.has_key?(:predicate_mapping) && mapping[:predicate_mapping].is_a?(Hash)
    true
  end
    

end


load File.join(File.dirname(__FILE__),"tasks/active_fedora.rake") if defined?(Rake)


