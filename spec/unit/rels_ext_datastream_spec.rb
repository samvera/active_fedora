require 'spec_helper'

describe ActiveFedora::RelsExtDatastream do
  before(:all) do
    @pid = "test:sample_pid"
  
    @sample_xml = Nokogiri::XML::Document.parse(@sample_xml_string)
  end
  
  before(:each) do
      mock_inner = double('inner object')
      @mock_repo = double('repository')
      @mock_repo.stub(:datastream_dissemination=>'My Content', :config=>{})
      mock_inner.stub(:repository).and_return(@mock_repo)
      mock_inner.stub(:pid).and_return(@pid)
      @test_ds = ActiveFedora::RelsExtDatastream.new(mock_inner, "RELS-EXT")
      @test_ds.stub(:profile).and_return({})
  end

  its(:metadata?) { should be_true}
  its(:controlGroup) { should == "X"}

  describe "#mimeType" do
    it 'should use the application/rdf+xml mime type' do
      @test_ds.mimeType.should == 'application/rdf+xml'
    end
  end

  describe "#changed?" do
    it "should be false when no changes have been made" do
      subject.model = double(:relationships_are_dirty? => false)
      subject.changed?.should == false
    end
    it "should be true when the model has changes" do
      subject.model = double(:relationships_are_dirty? => true)
      subject.changed?.should == true
    end
  end
  
  
  describe '#serialize!' do
    
    it "should generate new rdf/xml as the datastream content if the object has been changed" do
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('demo:10'))
      
      @test_ds.stub(:new? => true, :relationships => graph, :model => double(:relationships_are_dirty? =>true, :relationships_are_not_dirty! => true))
      @test_ds.serialize!
      EquivalentXml.equivalent?(@test_ds.content, "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\n        <rdf:Description rdf:about='info:fedora/test:sample_pid'>\n        <isMemberOf rdf:resource='demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/></rdf:Description>\n      </rdf:RDF>").should be_true
    end
  
  end

  describe '#to_rels_ext' do
    
    before(:all) do
      @sample_rels_ext_xml = <<-EOS
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
      @pid = "test:sample_pid"
    end
    
    it 'should serialize the relationships array to Fedora RELS-EXT rdf/xml' do
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('info:fedora/demo:10'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_part_of),  RDF::URI.new('info:fedora/demo:11'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new('info:fedora/demo:12'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:OtherModel"))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:SampleModel"))

      @test_ds.should_receive(:model).and_return(double("model", :relationships=>graph, :relationships_are_dirty= => true))
      EquivalentXml.equivalent?(@test_ds.to_rels_ext(), @sample_rels_ext_xml).should be_true
    end
    
    it 'should use mapped namespace prefixes when given' do
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('info:fedora/demo:10'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_part_of),  RDF::URI.new('info:fedora/demo:11'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new('info:fedora/demo:12'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:OtherModel"))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:SampleModel"))

      @test_ds.stub(:model).and_return(double("model", :relationships=>graph, :relationships_are_dirty= => true))
      rels = @test_ds.to_rels_ext()
      EquivalentXml.equivalent?(rels, @sample_rels_ext_xml).should be_true
      rels.should_not =~ /fedora:isMemberOf/
      rels.should_not =~ /fedora-model:hasModel/
      rels.should =~ /ns\d:isMemberOf/
      rels.should =~ /ns\d:hasModel/
      
      ActiveFedora::Predicates.predicate_config[:predicate_namespaces] = {:"fedora-model"=>"info:fedora/fedora-system:def/model#", :fedora=>"info:fedora/fedora-system:def/relations-external#"}
      rels = @test_ds.to_rels_ext()
      EquivalentXml.equivalent?(rels, @sample_rels_ext_xml).should be_true
      rels.should =~ /fedora:isMemberOf/
      rels.should =~ /fedora-model:hasModel/
      rels.should_not =~ /ns\d:isMemberOf/
      rels.should_not =~ /ns\d:hasModel/
      ActiveFedora::Predicates.predicate_config[:predicate_namespaces] = nil
    end
    
  end
  
  describe "#from_xml" do
    before(:all) do
      @test_obj = ActiveFedora::Base.new
      @test_obj.add_relationship(:is_member_of, "info:fedora/demo:10")
      @test_obj.add_relationship(:is_part_of, "info:fedora/demo:11")
      @test_obj.add_relationship(:conforms_to, "AnInterface", true)
      @test_obj.save
    end
    after(:all) do
      @test_obj.delete
    end
    it "should handle un-mapped predicates gracefully" do
      @test_obj.add_relationship("foo", "info:fedora/foo:bar")
      @test_obj.save
      @test_obj.relationships.size.should == 5 
      @test_obj.ids_for_outbound("foo").should == ["foo:bar"]
    end
    it "should automatically map un-mapped predicates" do
      xml = <<-EOS
        <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
          <rdf:Description rdf:about='info:fedora/test:sample_pid'>
            <isMemberOf rdf:resource='info:fedora/demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/>
            <isPartOf rdf:resource='info:fedora/demo:11' xmlns='info:fedora/fedora-system:def/relations-external#'/>
            <hasPart rdf:resource='info:fedora/demo:12' xmlns='info:fedora/fedora-system:def/relations-external#'/>
            <hasModel rdf:resource='info:fedora/afmodel:OtherModel' xmlns='info:fedora/fedora-system:def/model#'/>
            <hasModel rdf:resource='info:fedora/afmodel:SampleModel' xmlns='info:fedora/fedora-system:def/model#'/>
            <missing:hasOtherRelationship rdf:resource='info:fedora/demo:13' xmlns:missing='http://example.org/ns/missing'/>
          </rdf:Description>
        </rdf:RDF>
      EOS
      model = ActiveFedora::Base.new
      new_ds = ActiveFedora::RelsExtDatastream.new
      new_ds.model = model
      lambda { ActiveFedora::RelsExtDatastream.from_xml(xml, new_ds) }.should_not raise_exception
      new_ds.to_rels_ext.should =~ /missing:hasOtherRelationship/
    end
    it "should handle un-mapped literals" do
      xml = "
                <rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"  xmlns:oai=\"http://www.openarchives.org/OAI/2.0/\">
                  <rdf:Description rdf:about=\"info:fedora/changeme:3489\">
                    <hasModel xmlns=\"info:fedora/fedora-system:def/model#\" rdf:resource=\"info:fedora/afmodel:ActiveFedora_Base\"/>
                    <isPartOf xmlns=\"info:fedora/fedora-system:def/relations-external#\" rdf:resource=\"info:fedora/demo:11\"/>
                    <isMemberOf xmlns=\"info:fedora/fedora-system:def/relations-external#\" rdf:resource=\"info:fedora/demo:10\"/>
                    <oai:itemID>oai:hull.ac.uk:hull:2708</oai:itemID>
                  </rdf:Description>
                </rdf:RDF>"
      model = ActiveFedora::Base.new
      new_ds = ActiveFedora::RelsExtDatastream.new
      new_ds.model = model
      ActiveFedora::RelsExtDatastream.from_xml(xml, new_ds)
      new_ext = new_ds.to_rels_ext()
      new_ext.should match "<ns2:itemID>oai:hull.ac.uk:hull:2708</ns2:itemID>"
      
    end
  end
  
end
