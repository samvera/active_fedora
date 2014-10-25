module ActiveFedora::Rdf
  ##
  # A class of RdfResources to act as the primary/root resource associated
  # with a Datastream and ActiveFedora::Base object.
  #
  # @see ActiveFedora::RDFDatastream
  class ObjectResource < ActiveTriples::Resource
    configure base_uri: ActiveFedora.fedora.host
    attr_accessor :datastream

    def persist!
      return false unless datastream and datastream.respond_to? :digital_object
      @persisted ||= datastream.digital_object.save
    end

    def persisted?
      @persisted ||= (not datastream.new_record?)
    end

    # This overrides ActiveTriples to cast id (e.g. /test-1) to a fully qualifed URI
    def get_uri(uri_or_str)
      if uri_or_str.respond_to? :to_uri
        uri_or_str.to_uri
      elsif uri_or_str.kind_of? RDF::Node
        uri_or_str
      else
        uri_or_str = uri_or_str.to_s
        if uri_or_str.start_with? '_:'
          RDF::Node(uri_or_str[2..-1])
        elsif RDF::URI(uri_or_str).valid? and (URI.scheme_list.include?(RDF::URI.new(uri_or_str).scheme.upcase) or RDF::URI.new(uri_or_str).scheme == 'info')
          RDF::URI(uri_or_str)
        elsif base_uri && !uri_or_str.start_with?(base_uri.to_s)
          RDF::URI(ActiveFedora::Base.id_to_uri(uri_or_str))
        else
          raise RuntimeError, "could not make a valid RDF::URI from #{uri_or_str}"
        end
      end
    end
  end
end
