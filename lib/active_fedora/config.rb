module ActiveFedora
  class Config
    attr_reader :credentials
    def initialize(val)
      @credentials = val.symbolize_keys
      unless @credentials.has_key?(:url)
        raise ActiveFedora::ConfigurationError, "Fedora configuration must provide :url."
      end
    end
  end
end
