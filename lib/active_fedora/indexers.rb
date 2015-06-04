module ActiveFedora
  module Indexers
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :NullIndexer
      autoload :GlobalIndexer
    end
  end
end
