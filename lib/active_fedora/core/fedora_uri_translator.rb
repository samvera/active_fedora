# frozen_string_literal: true
module ActiveFedora::Core
  class FedoraUriTranslator
    SLASH = '/'
    def self.call(uri)
      #id = uri.to_s.sub(ActiveFedora.fedora.host + ActiveFedora.fedora.base_path, '')
      #id.start_with?(SLASH) ? id[1..-1] : id

      parsed_fedora_host = URI.parse(ActiveFedora.fedora.host).to_s
      segments = uri.to_s.gsub(parsed_fedora_host, '')
      relative_id = segments.gsub(ActiveFedora.fedora.base_path, '')
      if relative_id.start_with?(SLASH)
        relative_id[1..]
      else
        relative_id
      end
    end
  end
end
