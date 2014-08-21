module ActiveFedora::Rdf
  module DatastreamIndexing
    extend ActiveSupport::Concern
    include Indexing

    def apply_prefix(name)
      prefix + name.to_s
    end
  end
end

