require 'spec_helper'

describe ActiveFedora::RelsExtDatastream do
  describe "short_predicate" do
    it 'should parse' do
      expect(ActiveFedora::RelsExtDatastream.short_predicate('http://www.openarchives.org/OAI/2.0/itemID')).to eq(:oai_item_id)
    end
  end

  before(:all) do
    @pid = "test:sample_pid"

    @sample_xml = Nokogiri::XML::Document.parse(@sample_xml_string)
  end

  before(:each) do
      mock_inner = double('inner object')
      @mock_repo = double('repository')
      allow(@mock_repo).to receive(:datastream_dissemination).and_return('My Content')
      allow(@mock_repo).to receive(:config).and_return({})
      allow(mock_inner).to receive(:repository).and_return(@mock_repo)
      allow(mock_inner).to receive(:pid).and_return(@pid)
      @test_ds = ActiveFedora::RelsExtDatastream.new(mock_inner, "RELS-EXT")
      allow(@test_ds).to receive(:profile).and_return({})
  end

  describe '#metadata?' do
    subject { super().metadata? }
    it { is_expected.to be_truthy}
  end

  describe "#mimeType" do
    it 'should use the application/rdf+xml mime type' do
      expect(@test_ds.mimeType).to eq('application/rdf+xml')
    end
  end

  describe "#changed?" do
    it "should be false when no changes have been made" do
      expect(subject.changed?).to eq(false)
    end
    it "should be true when the model has changes" do
      subject.model = double(:relationships_are_dirty=>true)
      expect(subject.changed?).to eq(true)
    end
  end


  describe '#serialize!' do

    it "should generate new rdf/xml as the datastream content if the object has been changed" do
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('demo:10'))

      allow(@test_ds).to receive(:new?).and_return true
      allow(@test_ds).to receive(:relationships_are_dirty?).and_return true
      allow(@test_ds).to receive(:relationships).and_return graph
      allow(@test_ds).to receive(:model).and_return double(:relationships_are_dirty= => true)
      @test_ds.serialize!
      expect(EquivalentXml.equivalent?(@test_ds.content, "<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\n        <rdf:Description rdf:about='info:fedora/test:sample_pid'>\n        <isMemberOf rdf:resource='demo:10' xmlns='info:fedora/fedora-system:def/relations-external#'/></rdf:Description>\n      </rdf:RDF>")).to be_truthy
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

      expect(@test_ds).to receive(:model).and_return(double("model", :relationships=>graph, :relationships_are_dirty= => true))
      expect(EquivalentXml.equivalent?(@test_ds.to_rels_ext(), @sample_rels_ext_xml)).to be_truthy
    end

    it 'should use mapped namespace prefixes when given' do
      graph = RDF::Graph.new
      subject = RDF::URI.new "info:fedora/test:sample_pid"
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_member_of),  RDF::URI.new('info:fedora/demo:10'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:is_part_of),  RDF::URI.new('info:fedora/demo:11'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_part),  RDF::URI.new('info:fedora/demo:12'))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:OtherModel"))
      graph.insert RDF::Statement.new(subject, ActiveFedora::Predicates.find_graph_predicate(:has_model),  RDF::URI.new("info:fedora/afmodel:SampleModel"))

      allow(@test_ds).to receive(:model).and_return(double("model", :relationships=>graph, :relationships_are_dirty= => true))
      rels = @test_ds.to_rels_ext()
      expect(EquivalentXml.equivalent?(rels, @sample_rels_ext_xml)).to be_truthy
      expect(rels).not_to match(/fedora:isMemberOf/)
      expect(rels).not_to match(/fedora-model:hasModel/)
      expect(rels).to match(/ns\d:isMemberOf/)
      expect(rels).to match(/ns\d:hasModel/)

      ActiveFedora::Predicates.predicate_config[:predicate_namespaces] = {:"fedora-model"=>"info:fedora/fedora-system:def/model#", :fedora=>"info:fedora/fedora-system:def/relations-external#"}
      rels = @test_ds.to_rels_ext()
      expect(EquivalentXml.equivalent?(rels, @sample_rels_ext_xml)).to be_truthy
      expect(rels).to match(/fedora:isMemberOf/)
      expect(rels).to match(/fedora-model:hasModel/)
      expect(rels).not_to match(/ns\d:isMemberOf/)
      expect(rels).not_to match(/ns\d:hasModel/)
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
      expect(@test_obj.relationships.size).to eq(5)
      expect(@test_obj.ids_for_outbound("foo")).to eq(["foo:bar"])
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
      expect { ActiveFedora::RelsExtDatastream.from_xml(xml, new_ds) }.not_to raise_exception
      expect(new_ds.to_rels_ext).to match(/missing:hasOtherRelationship/)
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
      expect(new_ext).to match "<ns0:itemID>oai:hull.ac.uk:hull:2708</ns0:itemID>"

    end
  end

  describe "#short_predicate" do
    before(:all) do
      @original_mapping = ActiveFedora::Predicates.predicate_config[:predicate_mapping]
    end
    after(:all) do
      ActiveFedora::Predicates.predicate_config[:predicate_mapping] = @original_mapping
    end
    it "should find predicates regardless of order loaded or shared namespace prefixes" do
      ActiveFedora::Predicates.predicate_config[:predicate_mapping] = {
        "http://example.org/"=>{:ceo => 'Manager'},
        "http://example.org/zoo/wolves/"=>{:alpha => 'Manager'},
        "http://example.org/zoo/"=>{:keeper => 'Manager'}
        }
      expect(ActiveFedora::RelsExtDatastream.short_predicate("http://example.org/zoo/Manager")).to eq(:keeper)
      expect(ActiveFedora::RelsExtDatastream.short_predicate("http://example.org/zoo/wolves/Manager")).to eq(:alpha)
      expect(ActiveFedora::RelsExtDatastream.short_predicate("http://example.org/Manager")).to eq(:ceo)
    end
  end
end
