require 'rdf/rdfxml'

module ActiveFedora
# This class ensures that the RELS-EXT datastream is always serialized
# with an rdf:Description container for the properties
# the default behavior for RDF:RDFXML::Writer is to change that element if
# an rdf:type assertion is present; this is incompatible with Fedora 3
  class RDFXMLWriter < RDF::RDFXML::Writer
    # Display a subject.
    #
    # If the Haml template contains an entry matching the subject's rdf:type URI, that entry will be used as the template for this subject and it's properties.
    #
    # @example Displays a subject as a Resource Definition:
    #     <div typeof="rdfs:Resource" about="http://example.com/resource">
    #       <h1 property="dc:title">label</h1>
    #       <ul>
    #         <li content="2009-04-30T06:15:51Z" property="dc:created">2009-04-30T06:15:51+00:00</li>
    #       </ul>
    #     </div>
    #
    # @param [RDF::Resource] subject
    # @param [Hash{Symbol => Object}] options
    # @option options [:li, nil] :element(:div)
    #   Serialize using &lt;li&gt; rather than template default element
    # @option options [RDF::Resource] :rel (nil)
    #   Optional @rel property
    # @return [Nokogiri::XML::Element, {Namespace}]
    #
    def subject(subject, options = {})
      return if is_done?(subject)

      subject_done(subject)

      properties = properties_for_subject(subject)
      typeof = type_of(properties[RDF.type.to_s], subject)
      prop_list = order_properties(properties)

      add_debug {"subject: #{curie.inspect}, typeof: #{typeof.inspect}, props: #{prop_list.inspect}"}

      render_opts = {:typeof => typeof, :property_values => properties}.merge(options)

      render_subject_template(subject, prop_list, render_opts)
    end

    def type_of(type, subject)
      ""
    end
  end
end
