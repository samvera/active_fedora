require 'uri'
require 'rdf/rdfxml'

module ActiveFedora
# This class ensures that the RELS-EXT datastream is always serialized
# with an rdf:Description container for the properties
# the default behavior for RDF:RDFXML::Writer is to change that element if
# an rdf:type assertion is present; this is incompatible with Fedora
  class RDFXMLWriter < RDF::RDFXML::Writer
    def subject(subject, parent_node)
      
      raise RDF::WriterError, "Illegal use of subject #{subject.inspect}, not supported in RDF/XML" unless subject.resource?
      
      node = if !is_done?(subject)
        subject_not_done(subject, parent_node)
      elsif @force_RDF_about.include?(subject)
        force_about(subject, parent_node)
      end
      @force_RDF_about.delete(subject)

      parent_node.add_child(node) if node
    end

    private

    def force_about(subject, parent_node)
      add_debug {"subject: #{subject.inspect}, force about"}
      node = Nokogiri::XML::Element.new("rdf:Description", parent_node.document)
      if subject.is_a?(RDF::Node)
        node["rdf:nodeID"] = subject.id
      else
        node["rdf:about"] = relativize(subject)
      end
      node
    end

    def subject_not_done(subject, parent_node)
      subject_done(subject)
      properties = @graph.properties(subject)
      add_debug {"subject: #{subject.inspect}, props: #{properties.inspect}"}

      @graph.query(:subject => subject).each do |st|
        raise RDF::WriterError, "Illegal use of predicate #{st.predicate.inspect}, not supported in RDF/XML" unless st.predicate.uri?
      end

      prop_list = order_properties(properties)
      add_debug {"=> property order: #{prop_list.to_sentence}"}

      qname = "rdf:Description"
      prefixes[:rdf] = RDF.to_uri

      node = Nokogiri::XML::Element.new(qname, parent_node.document)
      
      if subject.is_a?(RDF::Node)
        # Only need nodeID if it's referenced elsewhere
        if ref_count(subject) > (@depth == 0 ? 0 : 1)
          node["rdf:nodeID"] = subject.id
        else
          node.add_child(Nokogiri::XML::Comment.new(node.document, "Serialization for #{subject}")) if RDF::RDFXML::debug?
        end
      else
        node["rdf:about"] = relativize(subject)
      end

      prop_list.each do |prop|
        prop_ref = RDF::URI.intern(prop)
        
        properties[prop].each do |object|
          raise RDF::WriterError, "Illegal use of object #{object.inspect}, not supported in RDF/XML" unless object.resource? || object.literal?

          @depth += 1
          predicate(prop_ref, object, node, properties[prop].length == 1)
          @depth -= 1
        end
      end
      node
    end

  end
end
