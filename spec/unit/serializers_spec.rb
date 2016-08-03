require 'spec_helper'

describe ActiveFedora::Attributes::Serializers do
  describe "deserialize_dates_from_form" do
    before do
      class Foo < ActiveFedora::Base
        attr_accessor :birthday
      end
    end
    after do
      Object.send(:remove_const, :Foo)
    end
    subject(:serializer) { Foo.new }
    it "deserializes dates" do
      serializer.attributes = { 'birthday(1i)' => '2012', 'birthday(2i)' => '10', 'birthday(3i)' => '31' }
      expect(serializer.birthday).to eq '2012-10-31'
    end
  end
end
