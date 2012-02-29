module ActiveFedora 
  class Config
    attr_reader :path, :values
    def initialize(config_path, env)
      @path = config_path
      @values = YAML.load(File.open(config_path))[env].symbolize_keys
      if @values[:url] && !@values[:user]
        ActiveSupport::Deprecation.warn("Using \":url\" in the fedora.yml file without :user and :password is no longer supported") 
        u = URI.parse @values[:url]
        @values[:user] = u.user
        @values[:password] = u.password
        @values[:url] = "#{u.scheme}://#{u.host}:#{u.port}#{u.path}"
      end
      unless @values.has_key?(:user) && @values.has_key?(:password) && @values.has_key?(:url)
        raise ActiveFedora::ConfigurationError, "You must provide user, password and url in the #{env} section of #{@path}"
      end
    # puts "File is #{config_path}, env: #{env}"
    # puts "VALUES ARE: #{@values}"
    end
  end
end
