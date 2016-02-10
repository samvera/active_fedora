module ActiveFedora
  class Config
    attr_reader :credentials
    def initialize(val)
      @credentials = val.deep_symbolize_keys
      return if @credentials.key?(:url)
      raise ActiveFedora::ConfigurationError, "Fedora configuration must provide :url."
    end
  end
end
