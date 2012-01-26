require 'spec_helper'
require File.join( File.dirname(__FILE__), "../../lib/active_fedora/rdf_xml_writer" )

describe ActiveFedora::RDFXMLWriter do
  before(:all) do
    @rdf_xml = <<-EOS
      <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
        <rdf:Description rdf:about='info:fedora/test:sample_pid'>
          <isMemberOf rdf:resource='info:fedora/demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <isPartOf rdf:resource='info:fedora/demo:11' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <hasPart rdf:resource='info:fedora/demo:12' xmlns='info:fedora/fedora-system:def/relations-external#'/>
          <hasModel rdf:resource='info:fedora/afmodel:OtherModel' xmlns='info:fedora/fedora-system:def/model#'/>
          <hasModel rdf:resource='info:fedora/afmodel:SampleModel' xmlns='info:fedora/fedora-system:def/model#'/>
        </rdf:Description>
      </rdf:RDF>
    EOS

    @rdf_xml_with_type = <<-EOS
      <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
        <rdf:Description rdf:about='info:fedora/test:sample_pid'>
        <isMemberOf rdf:resource='demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/>
        <type rdf:resource='http://purl.org/dc/dcmitype/Collection' xmlns='http://www.w3.org/1999/02/22-rdf-syntax-ns#' />
        </rdf:Description>
      </rdf:RDF>
    EOS

  end
  it "should serialize graphs using the rdf:Description element despite the presence of rdf:type statements" do
    graph = RDF::Graph.new
    subject = RDF::URI.new "info:fedora/test:sample_pid"
    graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('demo:10'))
    graph.insert RDF::Statement.new(subject, RDF::URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),  RDF::URI.new('http://purl.org/dc/dcmitype/Collection'))
    content = ActiveFedora::RDFXMLWriter.buffer do |writer|
      graph.each_statement do |statement|
        writer << statement
      end
    end
    content.should be_equivalent_to @rdf_xml_with_type
  end
  
  it 'should serialize graphs without rdf:type equivalently to RDF::RDFXML::Writer' do
    graph = RDF::Graph.new
    subject = RDF::URI.new "info:fedora/test:sample_pid"
    graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('info:fedora/demo:10'))
    graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_part_of),  RDF::URI.new('info:fedora/demo:11'))
    graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new('info:fedora/demo:12'))
    graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:OtherModel"))
    graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:SampleModel"))

    local_content = ActiveFedora::RDFXMLWriter.buffer do |writer|
      graph.each_statement do |statement|
        writer << statement
      end
    end
    generic_content = RDF::RDFXML::Writer.buffer do |writer|
      graph.each_statement do |statement|
        writer << statement
      end
    end
    EquivalentXml.equivalent?(local_content, @rdf_xml).should be_true
    EquivalentXml.equivalent?(local_content, generic_content).should be_true
  end
end
