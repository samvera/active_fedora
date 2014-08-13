module ActiveFedora
  class Fedora
    def initialize(config)
      @config = config
    end

    def host
      @config[:url]
    end

    def base_path
      @config[:base_path]
    end

    def connection
      @connection ||= Ldp::Client.new(host)
    end
  end
end
