require 'singleton'
require 'rubydora'

module ActiveFedora
  class RubydoraConnection
    include Singleton
    
    attr_reader :connection
    attr_accessor :options

    def self.connect(params={})
      if params.kind_of? String
        u = URI.parse params
        params = {}
        params[:user] = u.user
        params[:password] = u.password
        params[:url] = "#{u.scheme}://#{u.host}:#{u.port}#{u.path}"
      end
      instance = self.instance
      instance.options = params
      instance.connect
      instance
    end

    def connect()
      return unless @connection.nil?
      @connection = Rubydora.connect :url => options[:url], :user => options[:user], :password => options[:password]
    end

    def nextid(attrs={})
      d = REXML::Document.new(connection.next_pid(:namespace=>attrs[:namespace]))
      d.elements['//pid'].text
    end

    def find_model(pid, klass)
      klass.new(:pid=>pid)
    end

  end
end
