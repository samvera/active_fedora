require 'spec_helper'

describe 'Properties with the same predicate' do

  let(:warningMsg) {"Same predicate (http://purl.org/dc/terms/title) used for properties title1 and title2"}

  it "should warn" do

    # Note that the expect test must be before the class is parsed. 
    expect(ActiveFedora::Base.logger).to receive(:warn).with(warningMsg)

    module TestModel1
      class Book < ActiveFedora::Base
        property :title1, predicate: ::RDF::DC.title 
        property :title2, predicate: ::RDF::DC.title 
      end
    end      

  end
 
end


describe 'Properties with different predicate' do

  it "should not warn" do

    # Note that the expect test must be before the class is parsed. 
    expect(ActiveFedora::Base.logger).to_not receive(:warn)

    module TestModel2
      class Book < ActiveFedora::Base
        property :title1, predicate: ::RDF::DC.title
        property :title2, predicate: ::RDF::DC.creator
      end
    end

  end
  
end