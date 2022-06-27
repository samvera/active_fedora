# frozen_string_literal: true
module ActiveFedora
  module Indexers
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :NullIndexer
      autoload :GlobalIndexer
    end
  end
end
