module ActiveFedora::Indexers
  ##
  # An indexer which does nothing with the given index object.
  class NullIndexer
    include Singleton
    def new(_)
      self
    end

    def index(_); end
  end
end
