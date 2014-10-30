require 'spec_helper'
require 'config_helper'

describe ActiveFedora::FileConfigurator do
  
  before :all do
    class TestConfigurator
      attr_reader :fedora_config, :solr_config, :predicate_config
      
      def init(options = {})
        @fedora_config = options[:fedora_config]
        @solr_config = options[:solr_config]
        @predicate_config = options[:predicate_config]
      end
    end
    
    @config_params = {
      :fedora_config => { :url => 'http://codeconfig.example.edu/fedora/', :user => 'fedoraAdmin', :password => 'configurator', :cert_file => '/path/to/cert/file' },
      :solr_config => { :url => 'http://codeconfig.example.edu/solr/' },
      :predicate_config => { 
        :default_namespace => 'http://fedora.info/definitions/v4/rels-ext#',
        :predicate_mapping => {
          'http://fedora.info/definitions/v4/rels-ext#' => { :has_part => 'hasPart' } 
        }
      }
    }
  end
  
  before :each do
    ActiveFedora.configurator = TestConfigurator.new
  end
  
  after :all do
    unstub_rails
    # Restore to default fedora configs
    ActiveFedora.configurator = ActiveFedora::FileConfigurator.new
    restore_spec_configuration
  end

  it "should initialize from code" do
    expect(Psych).to receive(:load).never
    expect(File).to receive(:exists?).never
    expect(File).to receive(:read).never
    expect(File).to receive(:open).never
    ActiveFedora.init(@config_params)
    expect(ActiveFedora.fedora_config.credentials).to eq @config_params[:fedora_config]
    expect(ActiveFedora.solr_config).to eq @config_params[:solr_config]
    expect(ActiveFedora::Predicates.predicate_mappings['http://fedora.info/definitions/v4/rels-ext#'].length).to eq 1
  end
  
end
