module ActiveFedora::Rdf
  ##
  # A class of RdfResources to act as the primary/root resource associated
  # with a Datastream and ActiveFedora::Base object.
  #
  # @see ActiveFedora::RDFDatastream
  class ObjectResource < Resource
    configure :base_uri => 'info:fedora/'
    attr_accessor :datastream

    def persist!
      return false unless datastream and datastream.respond_to? :digital_object
      @persisted ||= datastream.digital_object.save
    end

    def persisted?
      @persisted ||= (not datastream.new?)
    end
  end
end
