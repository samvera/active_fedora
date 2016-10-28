require 'spec_helper'

describe ActiveFedora::Associations::Builder::HasAndBelongsToMany do
  describe "valid_options" do
    subject { described_class.valid_options({}) }
    it { is_expected.to match_array [:class_name, :predicate, :type_validator, :before_add, :after_add, :before_remove, :after_remove, :inverse_of, :solr_page_size, :autosave] }
  end
end
