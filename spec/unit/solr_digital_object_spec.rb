require 'spec_helper'

describe ActiveFedora::SolrDigitalObject do
  subject { ActiveFedora::SolrDigitalObject.new({}) }
  describe "when not finished" do
    it "should not respond_to? :repository" do
      subject.should_not respond_to :repository
    end
  end
  describe "when finished" do
    before do
      subject.freeze
    end
    it "should respond_to? :repository" do
      subject.should respond_to :repository
    end
  end


end
