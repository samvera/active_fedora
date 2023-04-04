require 'faraday/follow_redirects'

module ActiveFedora::File::Streaming
  # @param range [String] the Range HTTP header
  # @return [Stream] an object that responds to each
  def stream(range = nil)
    uri = URI.parse(self.uri)
    FileBody.new(uri, headers(range, nil))
  end

  # @param range [String] from #stream
  # @return [Hash]
  def headers(range, _key, result = {})
    result["Range"] = range if range
    result
  end

  class FileBody
    attr_reader :uri, :headers
    def initialize(uri, headers)
      @uri = uri
      @headers = headers
    end

    def each(no_of_requests_limit = 3)
      redirecting_connection(no_of_requests_limit).get(uri.to_s, nil, headers) do |req|
        req.options.on_data = proc do |chunk, overall_received_bytes, _env|
          yield chunk unless overall_received_bytes.zero? # Don't yield when redirecting
        end
      end
    rescue Faraday::FollowRedirects::RedirectLimitReached
      raise ArgumentError, 'HTTP redirect too deep'
    rescue Faraday::Error => ex
      raise "Couldn't get data from Fedora (#{uri}). Response: #{ex.response_status}"
    end

    private

      # Create a new faraday connection with follow_redirects enabled and configured using passed value
      def redirecting_connection(redirection_limit)
        options = {}
        options[:ssl] = ActiveFedora.fedora.ssl_options if ActiveFedora.fedora.ssl_options
        options[:request] = ActiveFedora.fedora.request_options if ActiveFedora.fedora.request_options
        Faraday.new(ActiveFedora.fedora.host, options) do |conn|
          conn.response :encoding # use Faraday::Encoding middleware
          conn.adapter Faraday.default_adapter # net/http
          if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('2')
            conn.request :basic_auth, ActiveFedora.fedora.user, ActiveFedora.fedora.password
          else
            conn.request :authorization, :basic, ActiveFedora.fedora.user, ActiveFedora.fedora.password
            conn.response :follow_redirects, limit: redirection_limit - 1 # Need to reduce by one to retain same behavior as before
          end
        end
      end
  end
end
