require 'spec_helper'

describe ActiveFedora::Predicates do
  describe "#short_predicate" do
    it 'parses strings' do
      expect(described_class.short_predicate('http://www.openarchives.org/OAI/2.0/itemID')).to eq :oai_item_id
    end
    it 'parses uris' do
      expect(described_class.short_predicate(RDF::DC.creator)).to eq 'dc_terms_creator'
      expect(described_class.short_predicate(RDF::SKOS.hasTopConcept)).to eq '2004_02_skos_core_has_top_concept'
    end
    before do
      @original_mapping = described_class.predicate_config[:predicate_mapping]
    end
    after do
      described_class.predicate_config[:predicate_mapping] = @original_mapping
    end
    it "finds predicates regardless of order loaded or shared namespace prefixes" do
      described_class.predicate_config[:predicate_mapping] = {
        "http://example.org/" => { ceo: 'Manager' },
        "http://example.org/zoo/wolves/" => { alpha: 'Manager' },
        "http://example.org/zoo/" => { keeper: 'Manager' }
      }
      expect(described_class.short_predicate("http://example.org/zoo/Manager")).to eq :keeper
      expect(described_class.short_predicate("http://example.org/zoo/wolves/Manager")).to eq :alpha
      expect(described_class.short_predicate("http://example.org/Manager")).to eq :ceo
    end
  end

  it 'provides .default_predicate_namespace' do
    expect(described_class.default_predicate_namespace).to eq 'info:fedora/fedora-system:def/relations-external#'
  end

  describe "#predicate_mappings" do
    it 'returns a hash' do
      expect(described_class.predicate_mappings).to be_kind_of Hash
    end

    it "provides mappings to the fedora ontology via the info:fedora/fedora-system:def/relations-external# default namespace mapping" do
      expect(described_class.predicate_mappings.keys.include?(described_class.default_predicate_namespace)).to be true
      expect(described_class.predicate_mappings[described_class.default_predicate_namespace]).to be_kind_of Hash
    end

    it 'provides predicate mappings for entire Fedora Relationship Ontology' do
      desired_mappings = Hash[is_member_of: "isMemberOf",
                              has_member: "hasMember",
                              is_part_of: "isPartOf",
                              has_part: "hasPart",
                              is_member_of_collection: "isMemberOfCollection",
                              has_collection_member: "hasCollectionMember",
                              is_constituent_of: "isConstituentOf",
                              has_constituent: "hasConstituent",
                              is_subset_of: "isSubsetOf",
                              has_subset: "hasSubset",
                              is_derivation_of: "isDerivationOf",
                              has_derivation: "hasDerivation",
                              is_dependent_of: "isDependentOf",
                              has_dependent: "hasDependent",
                              is_description_of: "isDescriptionOf",
                              has_description: "hasDescription",
                              is_metadata_for: "isMetadataFor",
                              has_metadata: "hasMetadata",
                              is_annotation_of: "isAnnotationOf",
                              has_annotation: "hasAnnotation",
                              has_equivalent: "hasEquivalent",
                              conforms_to: "conformsTo",
                              has_model: "hasModel"]
      desired_mappings.each_pair do |k, v|
        expect(described_class.predicate_mappings[described_class.default_predicate_namespace]).to have_key(k)
        expect(described_class.predicate_mappings[described_class.default_predicate_namespace][k]).to eq v
      end
    end
  end

  it 'provides #predicate_lookup that maps symbols to common RELS-EXT predicates' do
    expect(described_class).to respond_to(:predicate_lookup)
    expect(described_class.predicate_lookup(:is_part_of)).to eq "isPartOf"
    expect(described_class.predicate_lookup(:is_member_of)).to eq "isMemberOf"
    expect(described_class.predicate_lookup("isPartOfCollection")).to eq "isPartOfCollection"
    described_class.predicate_config[:predicate_mapping].merge!("some_namespace" => { has_foo: "hasFOO" })
    expect(described_class.find_predicate(:has_foo)).to eq ["hasFOO", "some_namespace"]
    expect(described_class.predicate_lookup(:has_foo, "some_namespace")).to eq "hasFOO"
    expect(lambda { described_class.predicate_lookup(:has_foo) }).to raise_error ActiveFedora::UnregisteredPredicateError
  end

  context 'initialization' do
    before :each do
      @old_predicate_config = Marshal.load(Marshal.dump(described_class.predicate_config))
    end

    after :each do
      described_class.predicate_config = @old_predicate_config
    end

    it 'allows explicit initialization of predicates' do
      expect(described_class.find_predicate(:is_part_of)).to eq ["isPartOf", "info:fedora/fedora-system:def/relations-external#"]
      described_class.predicate_config = {
        default_namespace: 'http://example.com/foo',
        predicate_mapping: {
          'http://example.com/foo' => { has_bar: 'hasBAR' }
        }
      }
      expect(described_class.find_predicate(:has_bar)).to eq ["hasBAR", "http://example.com/foo"]
      expect(lambda { described_class.find_predicate(:is_part_of) }).to raise_error ActiveFedora::UnregisteredPredicateError
    end

    it 'ensures that the configuration has the correct keys' do
      expect(lambda { described_class.predicate_config = { foo: 'invalid!' } }).to raise_error TypeError
    end

    it "allows adding predicates without wiping out existing predicates" do
      described_class.set_predicates("http://projecthydra.org/ns/relations#" => { has_profile: "hasProfile" },
                                     "info:fedora/fedora-system:def/relations-external#" => {
                                       references: "references",
                                       has_derivation: "cameFrom"
                                     })
      # New & Modified Predicates
      expect(described_class.find_predicate(:has_profile)).to eq ["hasProfile", "http://projecthydra.org/ns/relations#"]
      expect(described_class.find_predicate(:references)).to eq ["references", "info:fedora/fedora-system:def/relations-external#"]
      expect(described_class.find_predicate(:has_derivation)).to eq ["cameFrom", "info:fedora/fedora-system:def/relations-external#"]
      # Pre-Existing predicates should be unharmed
      expect(described_class.find_predicate(:is_part_of)).to eq ["isPartOf", "info:fedora/fedora-system:def/relations-external#"]
      expect(described_class.find_predicate(:is_governed_by)).to eq ["isGovernedBy", "http://projecthydra.org/ns/relations#"]
    end
  end
end
