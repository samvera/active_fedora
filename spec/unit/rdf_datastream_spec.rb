require 'spec_helper'

describe ActiveFedora::RDFDatastream do
  describe "a new instance" do
    its(:metadata?) { should be_true}
    its(:content_changed?) { should be_false}
  end
  describe "an instance that exists in the datastore, but hasn't been loaded" do
    before do 
      class MyDatastream < ActiveFedora::NtriplesRDFDatastream
        map_predicates do |map|
          map.title(:in => RDF::DC)
        end
      end
      class MyObj < ActiveFedora::Base
        has_metadata 'descMetadata', type: MyDatastream
      end
      @obj = MyObj.new
      @obj.descMetadata.title = 'Foobar'
      @obj.save
    end
    after do
      @obj.destroy
      Object.send(:remove_const, :MyDatastream)
      Object.send(:remove_const, :MyObj)
    end
    subject { @obj.reload.descMetadata } 
    it "should not load the descMetadata datastream when calling content_changed?" do
      @obj.inner_object.repository.should_not_receive(:datastream_dissemination).with(hash_including(:dsid=>'descMetadata'))
      subject.should_not be_content_changed
    end

    it "should allow asserting an empty string" do
      @obj.descMetadata.title = ['']
      @obj.descMetadata.title.should == ['']
    end
  end
end
