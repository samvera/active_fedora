require 'rdf'
require 'rdf/ntriples'

module ActiveFedora
  class DCRDFDatastream < NtriplesRDFDatastream

    # given a symbol, resolve the predicate as a RDF::URI
    # if the predicate is not in DC, return nil 
    def resolve_predicate(name)
      RDF::DC.send(name) if RDF::DC.respond_to? name
    end

  end
end
