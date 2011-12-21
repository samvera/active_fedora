require 'spec_helper'


describe ActiveFedora::Predicates do
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
    
    

end
