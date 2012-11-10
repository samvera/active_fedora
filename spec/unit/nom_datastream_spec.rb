require 'spec_helper'

describe ActiveFedora::NomDatastream do
  describe "test" do
    subject {
      class MyNomDatastream < ActiveFedora::NomDatastream
       
        set_terminology do |t|
          t.a :path => '//a', :accessor => lambda { |x| x.text }, :index => 'a_s'
          t.b :path => '//b', :index => 'b_s'
        end
      end	

      MyNomDatastream.from_xml '<root><a>123</a><b><c>asdf</c></b></root>'
    }

    it "should work" do
      subject.a.should include("123")
    end

    it "should to_solr" do
      subject.to_solr['a_s'].should include('123')
      subject.to_solr['b_s'].should include('asdf')
    end
  end
end