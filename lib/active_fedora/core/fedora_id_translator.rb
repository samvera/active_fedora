# frozen_string_literal: true
module ActiveFedora::Core
  class FedoraIdTranslator
    SLASH = '/'
    def self.call(id)
      id = URI::DEFAULT_PARSER.escape(id, '[]')
      id = "/#{id}" unless id.start_with? SLASH
      id = ActiveFedora.fedora.base_path + id unless ActiveFedora.fedora.base_path == SLASH || id.start_with?("#{ActiveFedora.fedora.base_path}/")
      ActiveFedora.fedora.host + id
    end
  end
end
