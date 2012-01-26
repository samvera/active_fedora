require 'spec_helper'

describe ActiveFedora::DCRDFDatastream do

  describe "an instance with content" do
    before do
      @subject = ActiveFedora::DCRDFDatastream.new(@inner_object, 'dc_rdf')
      @subject.content = File.new('spec/fixtures/dublin_core_rdf_descMetadata.nt').read
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
      @subject.dsid.should == 'dc_rdf'
    end
    it "should have fields" do
      @subject.publisher.should == ["Penn State"]
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
      @subject = ActiveFedora::DCRDFDatastream.new(@inner_object, 'dc_rdf')
      @subject.stubs(:pid => 'test:1')
    end
    it "should save and reload" do
      @subject.publisher= ["St. Martin's Press"]
      @subject.save
    end
  end

end
