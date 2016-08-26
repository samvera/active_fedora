require 'spec_helper'
require 'config_helper'

describe ActiveFedora::FileConfigurator do
  subject(:configurator) { ActiveFedora.configurator }

  after :all do
    unstub_rails
    # Restore to default fedora configs
    restore_spec_configuration
  end

  describe "#initialize" do
    it "triggers configuration reset (to empty defaults)" do
      expect_any_instance_of(described_class).to receive(:reset!)
      described_class.new
    end
  end

  describe "#config_options" do
    before do
      configurator.reset!
    end
    it "is an empty hash" do
      expect(configurator.config_options).to eq({})
    end
  end

  describe "#fedora_config" do
    before do
      configurator.reset!
    end
    it "triggers configuration to load" do
      expect(configurator).to receive(:load_fedora_config)
      configurator.fedora_config
    end
  end
  describe "#solr_config" do
    before do
      configurator.reset!
    end
    it "triggers configuration to load" do
      expect(configurator).to receive(:load_solr_config)
      configurator.solr_config
    end
  end

  describe "#reset!" do
    before { configurator.reset! }
    it "clears @fedora_config" do
      expect(configurator.instance_variable_get(:@fedora_config)).to eq({})
    end
    it "clears @solr_config" do
      expect(configurator.instance_variable_get(:@solr_config)).to eq({})
    end
    it "clears @config_options" do
      expect(configurator.instance_variable_get(:@config_options)).to eq({})
    end
  end

  describe "initialization methods" do
    describe "config_path(:fedora)" do
      it "uses the config_options[:config_path] if it exists" do
        expect(configurator).to receive(:config_options).and_return(fedora_config_path: "/path/to/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora.yml").and_return(true)
        expect(configurator.config_path(:fedora)).to eql("/path/to/fedora.yml")
      end

      it "looks in Rails.root/config/fedora.yml if it exists and no fedora_config_path passed in" do
        expect(configurator).to receive(:config_options).and_return({})
        stub_rails(root: "/rails/root")
        expect(File).to receive(:file?).with("/rails/root/config/fedora.yml").and_return(true)
        expect(configurator.config_path(:fedora)).to eql("/rails/root/config/fedora.yml")
        unstub_rails
      end

      it "looks in ./config/fedora.yml if neither rails.root nor :fedora_config_path are set" do
        expect(configurator).to receive(:config_options).and_return({})
        allow(Dir).to receive(:getwd).and_return("/current/working/directory")
        expect(File).to receive(:file?).with("/current/working/directory/config/fedora.yml").and_return(true)
        expect(configurator.config_path(:fedora)).to eql("/current/working/directory/config/fedora.yml")
      end

      it "returns default fedora.yml that ships with active-fedora if none of the above" do
        expect(configurator).to receive(:config_options).and_return({})
        expect(Dir).to receive(:getwd).and_return("/current/working/directory")
        expect(File).to receive(:file?).with("/current/working/directory/config/fedora.yml").and_return(false)
        expect(File).to receive(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"), 'config', 'fedora.yml'))).and_return(true)
        expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml') - or set Rails.root and put fedora.yml into \#{Rails.root}/config.")
        expect(configurator.config_path(:fedora)).to eql(File.expand_path(File.join(File.dirname("__FILE__"), 'config', 'fedora.yml')))
      end
    end

    describe "config_path(:solr)" do
      it "returns the solr_config_path if set in config_options hash" do
        allow(configurator).to receive(:config_options).and_return(solr_config_path: "/path/to/solr.yml")
        expect(File).to receive(:file?).with("/path/to/solr.yml").and_return(true)
        expect(configurator.config_path(:solr)).to eql("/path/to/solr.yml")
      end

      it "returns the solr.yml file in the same directory as the fedora.yml if it exists" do
        expect(configurator).to receive(:path).and_return("/path/to/fedora/config/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora/config/solr.yml").and_return(true)
        expect(configurator.config_path(:solr)).to eql("/path/to/fedora/config/solr.yml")
      end

      context "no solr.yml in same directory as fedora.yml and fedora.yml does not contain solr url" do
        before do
          allow(configurator).to receive(:config_options).and_return({})
          expect(configurator).to receive(:path).and_return("/path/to/fedora/config/fedora.yml")
          expect(File).to receive(:file?).with("/path/to/fedora/config/solr.yml").and_return(false)
        end
        after do
          unstub_rails
        end

        it "does not raise an error if there is not a solr.yml in the same directory as the fedora.yml and the fedora.yml has a solr url defined and look in rails.root" do
          stub_rails(root: "/rails/root")
          expect(File).to receive(:file?).with("/rails/root/config/solr.yml").and_return(true)
          expect(configurator.config_path(:solr)).to eql("/rails/root/config/solr.yml")
        end

        it "looks in ./config/solr.yml if no rails root" do
          allow(Dir).to receive(:getwd).and_return("/current/working/directory")
          expect(File).to receive(:file?).with("/current/working/directory/config/solr.yml").and_return(true)
          expect(configurator.config_path(:solr)).to eql("/current/working/directory/config/solr.yml")
        end

        it "returns the default solr.yml file that ships with active-fedora if no other option is set" do
          allow(Dir).to receive(:getwd).and_return("/current/working/directory")
          expect(File).to receive(:file?).with("/current/working/directory/config/solr.yml").and_return(false)
          expect(File).to receive(:file?).with(File.expand_path(File.join(File.dirname("__FILE__"), 'config', 'solr.yml'))).and_return(true)
          expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default solr.yml that comes with active-fedora.  If you want to override this, pass the path to solr.yml to ActiveFedora - ie. ActiveFedora.init(:solr_config_path => '/path/to/solr.yml') - or set Rails.root and put solr.yml into \#{Rails.root}/config.")
          expect(configurator.config_path(:solr)).to eql(File.expand_path(File.join(File.dirname("__FILE__"), 'config', 'solr.yml')))
        end
      end
    end

    describe "load_fedora_config" do
      before do
        configurator.reset!
      end
      it "loads the file specified in fedora_config_path" do
        allow(configurator).to receive(:load_solrizer_config)
        expect(configurator).to receive(:config_path).with(:fedora).and_return("/path/to/fedora.yml")
        expect(configurator).to receive(:load_solr_config)
        expect(IO).to receive(:read).with("/path/to/fedora.yml").and_return("development:\n url: http://devfedora:8983\ntest:\n  url: http://myfedora:8080")
        expect(configurator.load_fedora_config).to eq(url: "http://myfedora:8080")
        expect(configurator.fedora_config).to eq(url: "http://myfedora:8080")
      end

      it "allows sharding" do
        allow(configurator).to receive(:load_solrizer_config)
        expect(configurator).to receive(:config_path).with(:fedora).and_return("/path/to/fedora.yml")
        expect(configurator).to receive(:load_solr_config)
        expect(IO).to receive(:read).with("/path/to/fedora.yml").and_return("development:\n  url: http://devfedora:8983\ntest:\n- url: http://myfedora:8080\n- url: http://myfedora:8081")
        expect(configurator.load_fedora_config).to eq [{ url: "http://myfedora:8080" }, { url: "http://myfedora:8081" }]
        expect(configurator.fedora_config).to eq [{ url: "http://myfedora:8080" }, { url: "http://myfedora:8081" }]
      end

      it "parses the file using ERb" do
        allow(configurator).to receive(:load_solrizer_config)
        expect(configurator).to receive(:config_path).with(:fedora).and_return("/path/to/fedora.yml")
        expect(configurator).to receive(:load_solr_config)
        expect(IO).to receive(:read).with("/path/to/fedora.yml").and_return("development:\n  url: http://devfedora:<%= 8983 %>\ntest:\n  url: http://myfedora:<%= 8081 %>")
        expect(configurator.load_fedora_config).to eq(url: "http://myfedora:8081")
        expect(configurator.fedora_config).to eq(url: "http://myfedora:8081")
      end
    end

    describe "load_solr_config" do
      before do
        configurator.reset!
      end
      it "loads the file specified in solr_config_path" do
        allow(configurator).to receive(:load_solrizer_config)
        expect(configurator).to receive(:config_path).with(:solr).and_return("/path/to/solr.yml")
        expect(configurator).to receive(:load_fedora_config)
        expect(IO).to receive(:read).with("/path/to/solr.yml").and_return("development:\n  default:\n    url: http://devsolr:8983\ntest:\n  default:\n    url: http://mysolr:8080")
        expect(configurator.load_solr_config).to eq(url: "http://mysolr:8080")
        expect(configurator.solr_config).to eq(url: "http://mysolr:8080")
      end

      it "parses the file using ERb" do
        allow(configurator).to receive(:load_solrizer_config)
        expect(configurator).to receive(:config_path).with(:solr).and_return("/path/to/solr.yml")
        expect(configurator).to receive(:load_fedora_config)
        expect(IO).to receive(:read).with("/path/to/solr.yml").and_return("development:\n  default:\n    url: http://devsolr:<%= 8983 %>\ntest:\n  default:\n    url: http://mysolr:<%= 8081 %>")
        expect(configurator.load_solr_config).to eq(url: "http://mysolr:8081")
        expect(configurator.solr_config).to eq(url: "http://mysolr:8081")
      end

      it "includes update_path and select_path in solr_config" do
        allow(configurator).to receive(:load_solrizer_config)
        expect(configurator).to receive(:config_path).with(:solr).and_return("/path/to/solr.yml")
        expect(configurator).to receive(:load_fedora_config)
        expect(IO).to receive(:read).with("/path/to/solr.yml").and_return("test:\n  url: http://mysolr:8080\n  update_path: update_test\n  select_path: select_test\n")
        expect(configurator.solr_config[:update_path]).to eq('update_test')
        expect(configurator.solr_config[:select_path]).to eq('select_test')
      end
    end

    describe "load_configs" do
      describe "when config is not loaded" do
        before do
          configurator.instance_variable_set :@config_loaded, nil
        end
        it "loads the fedora and solr configs" do
          expect(configurator).to_not be_config_loaded
          configurator.load_configs
          expect(configurator).to be_config_loaded
        end
      end
      describe "when config is loaded" do
        before do
          configurator.instance_variable_set :@config_loaded, true
        end
        it "loads the fedora and solr configs" do
          expect(configurator).to receive(:load_config).never
          expect(configurator).to be_config_loaded
          configurator.load_configs
          expect(configurator).to be_config_loaded
        end
      end
    end

    describe "check_fedora_path_for_solr" do
      it "finds the solr.yml file and return it if it exists" do
        expect(configurator).to receive(:path).and_return("/path/to/fedora/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora/solr.yml").and_return(true)
        expect(configurator.check_fedora_path_for_solr).to eq "/path/to/fedora/solr.yml"
      end
      it "returns nil if the solr.yml file is not there" do
        expect(configurator).to receive(:path).and_return("/path/to/fedora/fedora.yml")
        expect(File).to receive(:file?).with("/path/to/fedora/solr.yml").and_return(false)
        expect(configurator.check_fedora_path_for_solr).to be_nil
      end
    end
  end

  describe "setting the environment and loading configuration" do
    before(:all) do
      @fake_rails_root = File.expand_path(File.dirname(__FILE__) + '/../fixtures/rails_root')
    end

    after(:all) do
      config_file = File.join(File.dirname(__FILE__), "..", "..", "config", "fedora.yml")
      environment = "test"
      ActiveFedora.init(environment: environment, fedora_config_path: config_file)
    end

    it "can tell its config paths" do
      configurator.init
      expect(configurator).to respond_to(:solr_config_path)
    end

    it "loads a config from the current working directory as a second choice" do
      allow(configurator).to receive(:load_solrizer_config)
      allow(Dir).to receive(:getwd).and_return(@fake_rails_root)
      configurator.init
      expect(configurator.config_path(:fedora)).to eql("#{@fake_rails_root}/config/fedora.yml")
      expect(configurator.solr_config_path).to eql("#{@fake_rails_root}/config/solr.yml")
    end

    it "loads the config that ships with this gem as a last choice" do
      allow(Dir).to receive(:getwd).and_return("/fake/path")
      allow(configurator).to receive(:load_solrizer_config)
      expect(ActiveFedora::Base.logger).to receive(:warn).with("Using the default fedora.yml that comes with active-fedora.  If you want to override this, pass the path to fedora.yml to ActiveFedora - ie. ActiveFedora.init(:fedora_config_path => '/path/to/fedora.yml') - or set Rails.root and put fedora.yml into \#{Rails.root}/config.").exactly(3).times
      configurator.init
      expected_config = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config"))
      expect(configurator.config_path(:fedora)).to eql(expected_config + '/fedora.yml')
      expect(configurator.solr_config_path).to eql(expected_config + '/solr.yml')
    end
    it "raises an error if you pass in a string" do
      expect(lambda { configurator.init("#{@fake_rails_root}/config/fake_fedora.yml") }).to raise_exception(ArgumentError)
    end
    it "raises an error if you pass in a non-existant config file" do
      expect(lambda { configurator.init(fedora_config_path: "really_fake_fedora.yml") }).to raise_exception(ActiveFedora::ConfigurationError)
    end

    describe "within Rails" do
      before do
        stub_rails(root: File.dirname(__FILE__) + '/../fixtures/rails_root')
      end

      after do
        unstub_rails
      end

      it "loads a config from Rails.root as a first choice" do
        allow(configurator).to receive(:load_solrizer_config)
        configurator.init
        expect(configurator.config_path(:fedora)).to eql("#{Rails.root}/config/fedora.yml")
        expect(configurator.solr_config_path).to eql("#{Rails.root}/config/solr.yml")
      end

      it "can tell what environment it is set to run in" do
        stub_rails(env: "development")
        configurator.init
        expect(ActiveFedora.environment).to eql("development")
      end
    end
  end
end
