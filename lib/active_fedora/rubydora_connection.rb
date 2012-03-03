require 'rubydora'

module ActiveFedora
  class RubydoraConnection
    
    attr_accessor :options, :connection

    def initialize(params={})
      params = params.dup
      self.options = params
      connect
    end

    def connect(force=false)
      return unless @connection.nil? or force
      allowable_options = [:url, :user, :password, :timeout, :open_timeout, :ssl_client_cert, :ssl_client_key, :validateChecksum]
      client_options = options.reject { |k,v| not allowable_options.include?(k) }
      #puts "CLIENT OPTS #{client_options.inspect}"
      @connection = Rubydora.connect client_options
    end
  end
end
