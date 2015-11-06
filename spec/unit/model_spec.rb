require 'spec_helper'

module SpecModelM
  class Basic < ActiveFedora::Base
  end
  class CamelCased
    include ActiveFedora::Model
    def name
      self.class.to_s
    end
  end
end

describe ActiveFedora::Model do

  describe '.solr_query_handler' do
    after do
      SpecModelM::Basic.solr_query_handler = 'standard' # reset to default
    end
    it 'should have a default' do
      expect(SpecModelM::Basic.solr_query_handler).to eq('standard')
    end
    it 'should be settable' do
      SpecModelM::Basic.solr_query_handler = 'search'
      expect(SpecModelM::Basic.solr_query_handler).to eq('search')
    end
  end

  describe 'URI translation' do
    before :each do
      @camel = SpecModelM::CamelCased.new
    end
    it '#to_class_uri' do
      expect(@camel.to_class_uri).to eq 'info:fedora/afmodel:SpecModelM_CamelCased'
    end

    context 'with the namespace declared in the model' do
      it '#to_class_uri' do
        expect(@camel).to receive(:pid_namespace).and_return('test-cModel')
        expect(@camel.to_class_uri).to eq 'info:fedora/test-cModel:SpecModelM_CamelCased'
      end
    end

    context 'with the suffix declared in the model' do
      it '#to_class_uri' do
        expect(@camel).to receive(:pid_suffix).and_return('-TEST-SUFFIX')
        expect(@camel.to_class_uri).to eq 'info:fedora/afmodel:SpecModelM_CamelCased-TEST-SUFFIX'
      end
    end

    describe '.classname_from_uri' do
      it 'should turn an afmodel URI into a Model class name' do
        expect(ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:SpecModelM_CamelCased')).to eq(['SpecModelM::CamelCased', 'afmodel'])
      end
      it 'should not change plurality' do
        expect(ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:MyMetadata')).to eq(['MyMetadata', 'afmodel'])
      end
      it 'should capitalize the first letter' do
        expect(ActiveFedora::Model.classname_from_uri('info:fedora/afmodel:image')).to eq(['Image', 'afmodel'])
      end
    end
  end

end
