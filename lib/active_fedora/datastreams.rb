module ActiveFedora
  module Datastreams
    extend ActiveSupport::Autoload
    # extend Deprecation

    autoload :NokogiriDatastreams, 'active_fedora/datastreams/nokogiri_datastreams'
  end
end
