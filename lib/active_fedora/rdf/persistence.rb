module ActiveFedora
  module Rdf
    #
    # Mixin for adding datastream persistence to an ActiveTriples::Resource 
    # descendant so that it may be used to back an ActiveFedora::RDFDatastream.
    #
    # @see ActiveFedora::RDFDatastream.resource_class
    # @see ActiveFedora::Rdf::ObjectResource
    #
    module Persistence
      extend ActiveSupport::Concern

      BASE_URI = 'info:fedora/'

      included do
        configure :base_uri => BASE_URI unless base_uri
        attr_accessor :datastream
      end
     
      # Overrides ActiveTriples::Resource
      def persist!
        return false unless datastream and datastream.respond_to? :digital_object
        @persisted ||= datastream.digital_object.save
      end

      # Overrides ActiveTriples::Resource
      def persisted?
        @persisted ||= (not datastream.new_record?)
      end
    end
  end
end
