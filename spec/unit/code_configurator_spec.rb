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
        :default_namespace => 'info:fedora/fedora-system:def/relations-external#',
        :predicate_mapping => {
          'info:fedora/fedora-system:def/relations-external#' => { :has_part => 'hasPart' } 
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
    Psych.should_receive(:load).never
    File.should_receive(:exists?).never
    File.should_receive(:read).never
    File.should_receive(:open).never
    ActiveFedora.init(@config_params)
    ActiveFedora.fedora_config.credentials.should == @config_params[:fedora_config]
    ActiveFedora.solr_config.should == @config_params[:solr_config]
    ActiveFedora::Predicates.predicate_mappings['info:fedora/fedora-system:def/relations-external#'].length.should == 1
  end
  
end
