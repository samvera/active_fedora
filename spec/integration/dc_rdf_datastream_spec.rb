require 'spec_helper'

describe ActiveFedora::DCRDFDatastream do
  before do
    class RdfTest < ActiveFedora::Base 
      has_metadata :name=>'rdf', :mimeType=>'text/plain', :type=>ActiveFedora::DCRDFDatastream
      delegate :description, :to=>'rdf'
      delegate :title, :to=>'rdf', :unique=>true
    end
    @subject = RdfTest.new
  end

  after do
    Object.send(:remove_const, :RdfTest)
  end

  it "should set and recall values" do
#    @subject.rdf = ActiveFedora::DCRDFDatastream.new
    @subject.title = 'War and Peace'
    @subject.save

    loaded = RdfTest.find(@subject.pid)
    loaded.title.should == 'War and Peace'
    
  end
end
