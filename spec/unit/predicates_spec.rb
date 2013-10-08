require 'spec_helper'

describe ActiveFedora::Predicates do
  describe "#short_predicate" do
    it 'should parse strings' do
      ActiveFedora::Predicates.short_predicate('http://www.openarchives.org/OAI/2.0/itemID').should == :oai_item_id
    end
    it 'should parse uris' do
      ActiveFedora::Predicates.short_predicate(RDF::DC.creator).should == 'dc_terms_creator'
      ActiveFedora::Predicates.short_predicate(RDF::SKOS.hasTopConcept).should == '2004_02_skos_core_has_top_concept'
    end
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
      ActiveFedora::Predicates.short_predicate("http://example.org/zoo/Manager").should == :keeper
      ActiveFedora::Predicates.short_predicate("http://example.org/zoo/wolves/Manager").should == :alpha
      ActiveFedora::Predicates.short_predicate("http://example.org/Manager").should == :ceo
    end
  end
  
  it 'should provide .default_predicate_namespace' do
    ActiveFedora::Predicates.default_predicate_namespace.should == 'info:fedora/fedora-system:def/relations-external#'
  end
 
  describe "#predicate_mappings" do 

    it 'should return a hash' do
      ActiveFedora::Predicates.predicate_mappings.should be_kind_of Hash
    end

    it "should provide mappings to the fedora ontology via the info:fedora/fedora-system:def/relations-external default namespace mapping" do
      ActiveFedora::Predicates.predicate_mappings.keys.include?(ActiveFedora::Predicates.default_predicate_namespace).should be_true
      ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace].should be_kind_of Hash
    end

    it 'should provide predicate mappings for entire Fedora Relationship Ontology' do
      desired_mappings = Hash[:is_member_of => "isMemberOf",
                            :has_member => "hasMember",
                            :is_part_of => "isPartOf",
                            :has_part => "hasPart",
                            :is_member_of_collection => "isMemberOfCollection",
                            :has_collection_member => "hasCollectionMember",
                            :is_constituent_of => "isConstituentOf",
                            :has_constituent => "hasConstituent",
                            :is_subset_of => "isSubsetOf",
                            :has_subset => "hasSubset",
                            :is_derivation_of => "isDerivationOf",
                            :has_derivation => "hasDerivation",
                            :is_dependent_of => "isDependentOf",
                            :has_dependent => "hasDependent",
                            :is_description_of => "isDescriptionOf",
                            :has_description => "hasDescription",
                            :is_metadata_for => "isMetadataFor",
                            :has_metadata => "hasMetadata",
                            :is_annotation_of => "isAnnotationOf",
                            :has_annotation => "hasAnnotation",
                            :has_equivalent => "hasEquivalent",
                            :conforms_to => "conformsTo",
                            :has_model => "hasModel"]
      desired_mappings.each_pair do |k,v|
        ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace].should have_key(k)
        ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace][k].should == v
      end
    end
  end

  it 'should provide #predicate_lookup that maps symbols to common RELS-EXT predicates' do
    ActiveFedora::Predicates.should respond_to(:predicate_lookup)
    ActiveFedora::Predicates.predicate_lookup(:is_part_of).should == "isPartOf"
    ActiveFedora::Predicates.predicate_lookup(:is_member_of).should == "isMemberOf"
    ActiveFedora::Predicates.predicate_lookup("isPartOfCollection").should == "isPartOfCollection"
    ActiveFedora::Predicates.predicate_config[:predicate_mapping].merge!({"some_namespace"=>{:has_foo=>"hasFOO"}})
    ActiveFedora::Predicates.find_predicate(:has_foo).should == ["hasFOO","some_namespace"]
    ActiveFedora::Predicates.predicate_lookup(:has_foo,"some_namespace").should == "hasFOO"
    lambda { ActiveFedora::Predicates.predicate_lookup(:has_foo) }.should raise_error ActiveFedora::UnregisteredPredicateError
  end
    
  context 'initialization' do
    before :each do
      @old_predicate_config = ActiveFedora::Predicates.predicate_config
    end
    
    after :each do
      ActiveFedora::Predicates.predicate_config = @old_predicate_config
    end
    
    it 'should allow explicit initialization of predicates' do
      ActiveFedora::Predicates.find_predicate(:is_part_of).should == ["isPartOf", "info:fedora/fedora-system:def/relations-external#"]
      ActiveFedora::Predicates.predicate_config = {
        :default_namespace => 'http://example.com/foo',
        :predicate_mapping => {
          'http://example.com/foo' => { :has_bar => 'hasBAR' }
        }
      }
      ActiveFedora::Predicates.find_predicate(:has_bar).should == ["hasBAR", "http://example.com/foo"]
      lambda { ActiveFedora::Predicates.find_predicate(:is_part_of) }.should raise_error ActiveFedora::UnregisteredPredicateError
    end
    
    it 'should ensure that the configuration has the correct keys' do
      lambda { ActiveFedora::Predicates.predicate_config = { :foo => 'invalid!' } }.should raise_error TypeError
    end

    it "should allow adding predicates without wiping out existing predicates" do
      ActiveFedora::Predicates.set_predicates({
                                                  "http://projecthydra.org/ns/relations#"=>{has_profile:"hasProfile"},
                                                  "info:fedora/fedora-system:def/relations-external#"=>{
                                                      references:"references",
                                                      has_derivation: "cameFrom"
                                                  },
                                              })
      # New & Modified Predicates
      ActiveFedora::Predicates.find_predicate(:has_profile).should == ["hasProfile", "http://projecthydra.org/ns/relations#"]
      ActiveFedora::Predicates.find_predicate(:references).should == ["references", "info:fedora/fedora-system:def/relations-external#"]
      ActiveFedora::Predicates.find_predicate(:has_derivation).should == ["cameFrom", "info:fedora/fedora-system:def/relations-external#"]
      # Pre-Existing predicates should be unharmed
      ActiveFedora::Predicates.find_predicate(:is_part_of).should == ["isPartOf", "info:fedora/fedora-system:def/relations-external#"]
      ActiveFedora::Predicates.find_predicate(:is_governed_by).should == ["isGovernedBy", "http://projecthydra.org/ns/relations#"]
    end

  end
  
end
