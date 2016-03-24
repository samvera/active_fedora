module ActiveFedora
  module RDF
    #
    # Mixin for adding datastream persistence to an ActiveTriples::Resource
    # descendant so that it may be used to back an ActiveFedora::RDFDatastream.
    #
    # @see ActiveFedora::RDFDatastream.resource_class
    # @see ActiveFedora::RDF::ObjectResource
    #
    module Persistence
      extend ActiveSupport::Concern

      BASE_URI = 'info:fedora/'.freeze

      included do
        configure base_uri: BASE_URI unless base_uri
        attr_accessor :datastream
      end

      # Overrides ActiveTriples::Resource
      def persist!
        return false unless datastream && datastream.respond_to?(:save)
        @persisted ||= datastream.save
      end

      # Overrides ActiveTriples::Resource
      def persisted?
        return true if frozen? && !datastream.new_record?
        @persisted ||= !datastream.new_record?
      end
    end
  end
end
