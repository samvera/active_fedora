require 'spec_helper'

describe ActiveFedora::Associations::HasManyAssociation do
  before do 
    class Book < ActiveFedora::Base
    end
    class Page < ActiveFedora::Base
    end
  end

  after do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Page)
  end

  subject { Book.new(pid: 'subject:a') }
  before {
    allow(subject).to receive_messages(:new_record? => false, save: true)
  }

  it "should call add_relationship" do
    reflection = Book.create_reflection(:has_many, 'pages', {:property=>'predicate'}, Book)
    allow(ActiveFedora::SolrService).to receive(:query).and_return([])
    ac = ActiveFedora::Associations::HasManyAssociation.new(subject, reflection)
    expect(ac).to receive(:callback).twice
    object = Page.new(:pid => 'object:b')
    allow(object).to receive_messages(:new_record? => false, save: true)
  
    expect(object).to receive(:add_relationship).with('predicate', subject)
 
    ac << object

  end
  
end
