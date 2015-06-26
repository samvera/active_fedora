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
  def headers(range, key, result = Hash.new)
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

    def each
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri, headers
        http.request request do |response|

          raise "Couldn't get data from Fedora (#{uri}). Response: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
          response.read_body do |chunk|
            yield chunk
          end
        end
      end
    end
  end

  private

    # @return [String] current authorization token from Ldp::Client
    def authorization_key
      self.ldp_source.client.http.headers.fetch("Authorization", nil)
    end

end
