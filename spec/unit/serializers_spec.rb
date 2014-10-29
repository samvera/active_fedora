require 'spec_helper'

describe ActiveFedora::Attributes::Serializers do
  subject { ActiveFedora::Base }
  describe "deserialize_dates_from_form" do
    before do
      class Foo < ActiveFedora::Base
        attr_accessor :birthday
      end
    end
    after do
      Object.send(:remove_const, :Foo)
    end
    subject { Foo.new }
    it "should deserialize dates" do
      subject.attributes = {'birthday(1i)' =>'2012', 'birthday(2i)' =>'10', 'birthday(3i)' => '31'}
      expect(subject.birthday).to eq '2012-10-31'
    end
  end

end
