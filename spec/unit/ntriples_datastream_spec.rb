require 'spec_helper'

describe ActiveFedora::NtriplesRDFDatastream do

  describe "an instance with content" do
    before do
      @subject = ActiveFedora::NtriplesRDFDatastream.new(@inner_object, 'mixed_rdf')
      @subject.content = File.new('spec/fixtures/mixed_rdf_descMetadata.nt').read
      @subject.stubs(:pid => 'test:1')
      @subject.stubs(:new? => false)
    end
    it "should have controlGroup" do
      @subject.controlGroup.should == 'M'
    end
    it "should have mimeType" do
      @subject.mimeType.should == 'text/plain'
    end
    it "should have dsid" do
      @subject.dsid.should == 'mixed_rdf'
    end
    it "should have fields" do
      @subject.created.should == ["2010-12-31"]
      @subject.title.should == ["Title of work"]
      @subject.publisher.should == ["Penn State"]
      @subject.based_near.should == ["New York, NY, US"]
      @subject.seeAlso.should == ["http://google.com/"]
    end
    it "should have method missing" do
      lambda{@subject.frank}.should raise_exception NoMethodError
    end

    it "should set fields" do
      @subject.publisher= "St. Martin's Press"
      @subject.publisher.should == ["St. Martin's Press"]
    end
    it "should append fields" do
      @subject.append(RDF::DC.publisher, "St. Martin's Press")
      @subject.publisher.should == ["Penn State", "St. Martin's Press"]
    end
  end

  describe "a new instance" do
    before do
      @subject = ActiveFedora::NtriplesRDFDatastream.new(@inner_object, 'dc_rdf')
      @subject.stubs(:pid => 'test:1')
    end
    it "should save and reload" do
      @subject.publisher= ["St. Martin's Press"]
      @subject.save
    end
  end
end
