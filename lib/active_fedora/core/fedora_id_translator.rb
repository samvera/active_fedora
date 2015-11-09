module ActiveFedora::Core
  class FedoraIdTranslator
    SLASH = '/'.freeze
    def self.call(id)
      id = URI.escape(id, '[]'.freeze)
      id = "/#{id}" unless id.start_with? SLASH
      unless ActiveFedora.fedora.base_path == SLASH || id.start_with?("#{ActiveFedora.fedora.base_path}/")
        id = ActiveFedora.fedora.base_path + id
      end
      ActiveFedora.fedora.host + id
    end
  end
end
