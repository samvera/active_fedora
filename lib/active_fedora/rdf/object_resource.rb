module ActiveFedora::Rdf
  ##
  # A class of RdfResources to act as the primary/root resource associated
  # with a Datastream and ActiveFedora::Base object.
  #
  # @see ActiveFedora::RDFDatastream
  class ObjectResource < ActiveTriples::Resource
    configure base_uri: FedoraLens.host
    attr_accessor :datastream

    def persist!
      return false unless datastream and datastream.respond_to? :digital_object
      @persisted ||= datastream.digital_object.save
    end

    def persisted?
      @persisted ||= (not datastream.new_record?)
    end
  end
end
