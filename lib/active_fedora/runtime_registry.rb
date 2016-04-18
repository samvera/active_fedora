require 'active_support/per_thread_registry'

module ActiveFedora
  class RuntimeRegistry
    extend ActiveSupport::PerThreadRegistry

    attr_accessor :solr_service, :fedora_connection
  end
end
