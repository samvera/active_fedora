# Starts a fedora server and a solr server on a random port and then
# yields the passed block
def with_test_server(&block)
  with_server('test', &block)
end

class TestServer
  attr_reader :environment

  # @param [String] environment typically either 'development' or 'test'
  # @param [Hash] fcrepo_options options for fcrepo
  # @param [Hash] solr_options options for solr
  def initialize(environment, fcrepo_options, solr_options)
    @environment = environment
    @fcrepo_options = fcrepo_options
    @solr_options = solr_options
  end

  def start
    ENV["#{environment}_SERVER_STARTED"] = 'true'
    s_params = solr_params
    solr_config_path = s_params.delete(:solr_config_path)
    SolrWrapper.wrap(s_params) do |solr|
      ENV["SOLR_#{environment.upcase}_PORT"] = solr.port
      solr.with_collection(name: "hydra-#{environment}",
                           dir: solr_config_path) do
        FcrepoWrapper.wrap(fcrepo_params) do |fcrepo|
          ENV["FCREPO_#{environment.upcase}_PORT"] = fcrepo.port
          yield
        end
      end
    end
    ENV["#{environment}_SERVER_STARTED"] = 'false'
  end

  private
    def solr_params
      solr_config_path = File.join('solr', 'config')
      # Check to see if configs exist in a path relative to the working directory
      unless Dir.exist?(solr_config_path)
        $stderr.puts "Solr configuration not found at #{solr_config_path}. Using ActiveFedora defaults"
        # Otherwise use the configs delivered with ActiveFedora.
        solr_config_path = File.join(File.expand_path("../..", File.dirname(__FILE__)), "solr", "config")
      end
      defaults = { verbose: true, managed: true,
                   solr_config_path: solr_config_path }
      @solr_options.reverse_merge defaults
    end

    def fcrepo_params
      fcrepo_home = ENV.fetch('FCREPO_HOME', "fcrepo4-#{environment}-data")

      defaults = { verbose: true, managed: true,
                   enable_jms: false,
                   fcrepo_home_dir: fcrepo_home }
      @fcrepo_options.reverse_merge defaults
    end
end

def with_server(environment, fcrepo_port: nil, solr_port: nil, fcrepo_options: {}, solr_options: {}, &block)

  return yield if ENV["#{environment}_SERVER_STARTED"]

  # NOTE: setting port to nil assigns a random port.
  solr_options = solr_options.reverse_merge(port: solr_port)
  fcrepo_options = fcrepo_options.reverse_merge(port: fcrepo_port)
  TestServer.new(environment, fcrepo_options, solr_options).start(&block)
end

