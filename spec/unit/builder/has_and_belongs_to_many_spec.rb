require 'spec_helper'

describe ActiveFedora::Associations::Builder::HasAndBelongsToMany do
  describe "valid_options" do
    subject { ActiveFedora::Associations::Builder::HasAndBelongsToMany.valid_options }
    it { should eq [:class_name, :predicate, :type_validator, :before_add, :after_add, :before_remove,
                    :after_remove, :inverse_of, :solr_page_size, :autosave] }
  end
end
