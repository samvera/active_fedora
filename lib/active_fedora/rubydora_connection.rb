require 'singleton'
require 'rubydora'

module ActiveFedora
  class RubydoraConnection
    include Singleton
    
    attr_accessor :options

    def self.connect(params={})
      params = params.dup
      instance = self.instance
      force = params.delete(:force)
      instance.options = params
      instance.connect force
      instance
    end

    def connection
      return @connection if @connection
      ActiveFedora.load_configs
      ActiveFedora::RubydoraConnection.connect(ActiveFedora.config.credentials)
      @connection
    end
    

    def connect(force=false)
      return unless @connection.nil? or force
      allowable_options = [:url, :user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key, :validateChecksum]
      client_options = options.reject { |k,v| not allowable_options.include?(k) }
      #puts "CLIENT OPTS #{client_options.inspect}"
      @connection = Rubydora.connect client_options
    end

    def nextid(attrs={})
      raise RuntimeError "When using shards, you cannot use nextid to create a pid" if ActiveFedora.config.sharded?
      d = REXML::Document.new(connection.next_pid(:namespace=>attrs[:namespace]))
      d.elements['//pid'].text
    end

    def find_model(pid, klass)
      klass.allocate.init_with(DigitalObject.find(klass, pid))
    end

  end
end
