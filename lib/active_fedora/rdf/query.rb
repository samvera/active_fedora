module ActiveFedora::Rdf
  class Query 

    delegate *(Array.public_instance_methods + [:as_json]), to: :target

    def initialize(term)
      @term = term
    end

    def target
      @target ||= load_target
    end

    private
      def load_target
        result = @term.parent.query(subject: @term.rdf_subject, predicate: @term.predicate)
        .map{|x| convert_object(x.object)}
        .reject(&:nil?)
        return result if !@term.property_config || @term.property_config[:multivalue]
        result.first
      end

      # Converts an object to the appropriate class.
      def convert_object(value)
        case value
        when RDF::Literal
          value.object 
        when RDF::Resource
          @term.make_node(value)
        else
          value
        end
      end
  end
end
