module ActiveFedora::File::External

  HANDLING_TYPES = ['redirect', 'proxy', 'copy']

  def external_uri
    @external_uri ||= fetch_external_uri
  end

  def external_uri=(uri)
    @external_uri = uri
  end

  def external_handling=(handling)
    @external_handling = handling
  end

  def external_handling
    @external_handling ||= fetch_external_handling
  end

  private

    def fetch_external_uri
      return if new_record?
      ldp_source.head.response.headers['Content-Location']
    end

    def fetch_external_handling
      return if new_record?
      response = ldp_source.head.response
      return unless response.headers.key?('Content-Location')

      case response.status
      when Net::HTTPRedirection
        'redirect'
      when Net::HTTPSuccess
        'proxy'
      end
    end
end
