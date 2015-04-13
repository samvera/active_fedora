module ActiveFedora::Core
  class FedoraUriTranslator
    SLASH = '/'.freeze
    def self.call(uri)
      id = uri.to_s.sub(ActiveFedora.fedora.host + ActiveFedora.fedora.base_path, '')
      id.start_with?(SLASH) ? id[1..-1] : id
    end
  end
end
