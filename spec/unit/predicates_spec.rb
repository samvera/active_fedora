require 'spec_helper'


describe ActiveFedora::Predicates do
  it 'should provide .default_predicate_namespace' do
    expect(ActiveFedora::Predicates.default_predicate_namespace).to eq('info:fedora/fedora-system:def/relations-external#')
  end

  describe "#predicate_mappings" do

    it 'should return a hash' do
      expect(ActiveFedora::Predicates.predicate_mappings).to be_kind_of Hash
    end

    it "should provide mappings to the fedora ontology via the info:fedora/fedora-system:def/relations-external default namespace mapping" do
      expect(ActiveFedora::Predicates.predicate_mappings.keys.include?(ActiveFedora::Predicates.default_predicate_namespace)).to be_truthy
      expect(ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace]).to be_kind_of Hash
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
        expect(ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace]).to have_key(k)
        expect(ActiveFedora::Predicates.predicate_mappings[ActiveFedora::Predicates.default_predicate_namespace][k]).to eq(v)
      end
    end
  end

  it 'should provide #predicate_lookup that maps symbols to common RELS-EXT predicates' do
    expect(ActiveFedora::Predicates).to respond_to(:predicate_lookup)
    expect(ActiveFedora::Predicates.predicate_lookup(:is_part_of)).to eq("isPartOf")
    expect(ActiveFedora::Predicates.predicate_lookup(:is_member_of)).to eq("isMemberOf")
    expect(ActiveFedora::Predicates.predicate_lookup("isPartOfCollection")).to eq("isPartOfCollection")
    ActiveFedora::Predicates.predicate_config[:predicate_mapping].merge!({"some_namespace"=>{:has_foo=>"hasFOO"}})
    expect(ActiveFedora::Predicates.find_predicate(:has_foo)).to eq(["hasFOO","some_namespace"])
    expect(ActiveFedora::Predicates.predicate_lookup(:has_foo,"some_namespace")).to eq("hasFOO")
    expect { ActiveFedora::Predicates.predicate_lookup(:has_foo) }.to raise_error ActiveFedora::UnregisteredPredicateError
  end

  context 'initialization' do
    before :each do
      @old_predicate_config = ActiveFedora::Predicates.predicate_config
    end

    after :each do
      ActiveFedora::Predicates.predicate_config = @old_predicate_config
    end

    it 'should allow explicit initialization of predicates' do
      expect(ActiveFedora::Predicates.find_predicate(:is_part_of)).to eq(["isPartOf", "info:fedora/fedora-system:def/relations-external#"])
      ActiveFedora::Predicates.predicate_config = {
        :default_namespace => 'http://example.com/foo',
        :predicate_mapping => {
          'http://example.com/foo' => { :has_bar => 'hasBAR' }
        }
      }
      expect(ActiveFedora::Predicates.find_predicate(:has_bar)).to eq(["hasBAR", "http://example.com/foo"])
      expect { ActiveFedora::Predicates.find_predicate(:is_part_of) }.to raise_error ActiveFedora::UnregisteredPredicateError
    end

    it 'should ensure that the configuration has the correct keys' do
      expect { ActiveFedora::Predicates.predicate_config = { :foo => 'invalid!' } }.to raise_error TypeError
    end

  end

end
