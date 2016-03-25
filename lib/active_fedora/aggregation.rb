module ActiveFedora
  module Aggregation
    extend ActiveSupport::Autoload
    eager_autoload do
      autoload :Proxy
      autoload :BaseExtension
      autoload :OrderedReader
      autoload :ListSource
    end
  end
end
