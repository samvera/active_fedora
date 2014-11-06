module ActiveFedora::Rdf
  module DatastreamIndexing
    extend ActiveSupport::Concern
    include Indexing

    def apply_prefix(name, file_path)
      prefix(file_path) + name.to_s
    end
  end
end

