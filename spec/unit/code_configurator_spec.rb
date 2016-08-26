require 'spec_helper'
require 'config_helper'

describe ActiveFedora::FileConfigurator do
  before :all do
    class TestConfigurator
      attr_reader :fedora_config, :solr_config

      def init(options = {})
        @fedora_config = options[:fedora_config]
        @solr_config = options[:solr_config]
      end
    end

    @config_params = {
      fedora_config: { url: 'http://codeconfig.example.edu/fedora/', user: 'fedoraAdmin', password: 'configurator', cert_file: '/path/to/cert/file' },
      solr_config: { url: 'http://codeconfig.example.edu/solr/' }
    }
  end

  before do
    ActiveFedora.configurator = TestConfigurator.new
  end

  after :all do
    unstub_rails
    # Restore to default fedora configs
    ActiveFedora.configurator = described_class.new
    restore_spec_configuration
  end

  it "initializes from code" do
    expect(Psych).to receive(:load).never
    expect(File).to receive(:exists?).never
    expect(File).to receive(:read).never
    expect(File).to receive(:open).never
    ActiveFedora.init(@config_params)
    expect(ActiveFedora.fedora_config.credentials).to eq @config_params[:fedora_config]
    expect(ActiveFedora.solr_config).to eq @config_params[:solr_config]
  end
end
