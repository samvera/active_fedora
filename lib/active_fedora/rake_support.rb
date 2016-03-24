# Starts a fedora server and a solr server on a random port and then
# yields the passed block
def with_test_server(&block)
  with_server('test', &block)
end

def with_server(environment, fcrepo_port: nil, solr_port: nil)
  return yield if ENV["#{environment}_SERVER_STARTED"]

  ENV["#{environment}_SERVER_STARTED"] = 'true'

  # setting port: nil assigns a random port.
  solr_params = { port: solr_port, verbose: true, managed: true }
  fcrepo_params = { port: fcrepo_port, verbose: true, managed: true,
                    enable_jms: false, fcrepo_home_dir: "fcrepo4-#{environment}-data" }
  SolrWrapper.wrap(solr_params) do |solr|
    ENV["SOLR_#{environment.upcase}_PORT"] = solr.port
    solr_config_path = File.join('solr', 'config')
    # Check to see if configs exist in a path relative to the working directory
    unless Dir.exist?(solr_config_path)
      $stderr.puts "Solr configuration not found at #{solr_config_path}. Using ActiveFedora defaults"
      # Otherwise use the configs delivered with ActiveFedora.
      solr_config_path = File.join(File.expand_path("../..", File.dirname(__FILE__)), "solr", "config")
    end
    solr.with_collection(name: "hydra-#{environment}", dir: solr_config_path) do
      FcrepoWrapper.wrap(fcrepo_params) do |fcrepo|
        ENV["FCREPO_#{environment.upcase}_PORT"] = fcrepo.port
        yield
      end
    end
  end
  ENV["#{environment}_SERVER_STARTED"] = 'false'
end

# Run a fedora server and a solr server until interrupted by the user
def run_server(environment, solr_port: nil, fcrepo_port: nil)
  with_server(environment, solr_port: solr_port, fcrepo_port: fcrepo_port) do
    puts "\n#{environment.titlecase} servers running:\n"
    puts "    Fedora..: http://localhost:#{fcrepo_port}/rest/"
    puts "    Solr....: http://localhost:#{solr_port}/solr/hydra-#{environment}/"
    puts "\n^C to stop"
    begin
      yield
    rescue Interrupt
      puts "Shutting down..."
    end
  end
end
