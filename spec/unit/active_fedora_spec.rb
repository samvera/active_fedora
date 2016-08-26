require 'spec_helper'
require 'config_helper'

# For testing Module-level methods like ActiveFedora.init

describe ActiveFedora do
  before do
    restore_spec_configuration
  end

  after :all do
    unstub_rails
    # Restore to default fedora configs
    restore_spec_configuration
  end

  describe "validate Fedora URL" do
    let(:good_url) { described_class.fedora_config.credentials[:url] }
    let(:bad_url) { good_url.gsub('/rest', '/') }
    let(:user) { described_class.fedora_config.credentials[:user] }
    let(:password) { described_class.fedora_config.credentials[:password] }

    it "connects OK" do
      expect(ActiveFedora::Base.logger).to_not receive(:warn)
      ActiveFedora::Fedora.new(url: good_url, base_path: '/test', user: user, password: password)
    end

    it "does not connect and warn" do
      expect(ActiveFedora::Base.logger).to receive(:warn)
      expect {
        ActiveFedora::Fedora.new(url: bad_url, base_path: '/test', user: user, password: password).connection.head
      }.to raise_error Ldp::HttpError
    end
  end

  describe "initialization methods" do
    describe "environment" do
      it "uses config_options[:environment] if set" do
        allow(described_class).to receive(:config_options).and_return(environment: "ballyhoo")
        expect(described_class.environment).to eql("ballyhoo")
      end

      it "uses Rails.env if no config_options and Rails.env is set" do
        stub_rails(env: "bedbugs")
        allow(described_class).to receive(:config_options).and_return({})
        expect(described_class.environment).to eql("bedbugs")
        unstub_rails
      end

      it "uses ENV['environment'] if neither config_options nor Rails.env are set" do
        ENV['environment'] = "wichita"
        allow(described_class).to receive(:config_options).and_return({})
        expect(described_class.environment).to eql("wichita")
        ENV['environment'] = 'test'
      end

      it "uses ENV['RAILS_ENV'] and log a warning if none of the above are set" do
        ENV['environment'] = nil
        ENV['RAILS_ENV'] = "rails_env"
        expect { described_class.environment }.to raise_error(RuntimeError, "You're depending on RAILS_ENV for setting your environment. Please use ENV['environment'] for non-rails environment setting: 'rake foo:bar environment=test'")
        ENV['environment'] = 'test'
      end

      it "is development if none of the above are present" do
        ENV['environment'] = nil
        ENV['RAILS_ENV'] = nil
        allow(described_class).to receive(:config_options).and_return({})
        expect(described_class.environment).to eq 'development'
        ENV['environment'] = "test"
      end
    end
  end

  describe ".init" do
    after do
      # Restore to default fedora configs
      described_class.init(environment: "test", fedora_config_path: File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml"))
    end

    describe "outside of rails" do
      it "loads the passed config if explicit config passed in as a string" do
        described_class.init(fedora_config_path: './spec/fixtures/rails_root/config/fedora.yml', environment: 'test')
        expect(described_class.config.credentials).to eq(url: "http://testhost.com:8983/fedora", user: 'fedoraAdmin', password: 'fedoraAdmin')
      end
    end

    describe "within rails" do
      after do
        unstub_rails
      end

      describe "versions prior to 3.0" do
        describe "with explicit config path passed in" do
          it "loads the specified config path" do
            fedora_config = "test:\n  url: http://fedoraAdmin:fedoraAdmin@127.0.0.1:8983/fedora"
            solr_config = "test:\n  default:\n    url: http://foosolr:8983"

            fedora_config_path = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/rails_root/config/fedora.yml"))
            solr_config_path = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/rails_root/config/solr.yml"))
            allow(File).to receive(:open).with(fedora_config_path).and_return(fedora_config)
            allow(File).to receive(:open).with(solr_config_path).and_return(solr_config)

            described_class.init(fedora_config_path: fedora_config_path, solr_config_path: solr_config_path)
            expect(described_class.solr.class).to eq ActiveFedora::SolrService
          end
        end

        describe "with no explicit config path" do
          it "looks for the file in the path defined at Rails.root" do
            stub_rails(root: File.join(File.dirname(__FILE__), "../fixtures/rails_root"))
            described_class.init
            expect(described_class.config.credentials[:url]).to eq "http://testhost.com:8983/fedora"
          end
        end
      end
    end
  end
end
