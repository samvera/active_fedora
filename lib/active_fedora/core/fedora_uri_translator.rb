# frozen_string_literal: true
module ActiveFedora::Core
  class FedoraUriTranslator
    def self.call(uri)
      path_segments = uri.path.split("/")
      path_segments.last
    end
  end
end
