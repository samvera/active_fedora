module ActiveFedora::File::Streaming
  # @param range [String] the Range HTTP header
  # @return [Stream] an object that responds to each
  def stream(range = nil)
    uri = URI.parse(self.uri)
    FileBody.new(uri, headers(range, authorization_key))
  end

  # @param range [String] from #stream
  # @param key [String] from #authorization_key
  # @return [Hash]
  def headers(range, key, result = {})
    result["Range"] = range if range
    result["Authorization"] = key if key
    result
  end

  class FileBody
    attr_reader :uri, :headers
    def initialize(uri, headers)
      @uri = uri
      @headers = headers
    end

    def each(no_of_requests_limit = 3, &block)
      raise ArgumentError, 'HTTP redirect too deep' if no_of_requests_limit == 0
      Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
        request = Net::HTTP::Get.new uri, headers
        http.request request do |response|
          case response
          when Net::HTTPSuccess
            response.read_body do |chunk|
              yield chunk
            end
          when Net::HTTPRedirection
            no_of_requests_limit -= 1
            @uri = URI(response["location"])
            each(no_of_requests_limit, &block)
          else
            raise "Couldn't get data from Fedora (#{uri}). Response: #{response.code}"
          end
        end
      end
    end
  end

  private

    # @return [String] current authorization token from Ldp::Client
    def authorization_key
      ldp_source.client.http.headers.fetch("Authorization", nil)
    end
end
