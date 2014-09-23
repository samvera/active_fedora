module ActiveFedora
  module Rdf
    ##
    # A class of RdfResources to act as the primary/root resource associated
    # with a Datastream and ActiveFedora::Base object.
    #
    # @see ActiveFedora::RDFDatastream
    class ObjectResource < ActiveTriples::Resource
      include Persistence
    end
  end
end
