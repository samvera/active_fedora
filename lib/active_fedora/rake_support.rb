# Starts a fedora server and a solr server on a random port and then
# yields the passed block
def with_test_server(&block)
  with_server('test', &block)
end

def with_server(environment)
  return yield if ENV["#{environment}_SERVER_STARTED"]

  ENV["#{environment}_SERVER_STARTED"] = 'true'

  # setting port: nil assigns a random port.
  solr_defaults = { port: nil, verbose: true, managed: true }
  fcrepo_defaults = { port: nil, verbose: true, managed: true,
                      enable_jms: false, fcrepo_home_dir: "tmp/fcrepo4-#{environment}-data" }

  SolrWrapper.wrap(load_config(:solr, environment, solr_defaults)) do |solr|
    ENV["SOLR_#{environment.upcase}_PORT"] = solr.port.to_s
    solr_config_path = File.join('solr', 'conf')
    # Check to see if configs exist in a path relative to the working directory
    unless Dir.exist?(solr_config_path)
      $stderr.puts "Solr configuration not found at #{solr_config_path}. Using ActiveFedora defaults"
      # Otherwise use the configs delivered with ActiveFedora.
      solr_config_path = File.join(File.expand_path("../..", File.dirname(__FILE__)), 'lib', 'generators', 'active_fedora', 'config', 'solr', 'templates', 'solr', 'conf')
    end
    solr.with_collection(name: "hydra-#{environment}", dir: solr_config_path) do
      FcrepoWrapper.wrap(load_config(:fcrepo, environment, fcrepo_defaults)) do |fcrepo|
        ENV["FCREPO_#{environment.upcase}_PORT"] = fcrepo.port.to_s
        yield
      end
    end
  end
  ENV["#{environment}_SERVER_STARTED"] = 'false'
end

private

def load_config(service, environment, defaults)
  config_file = environment == 'test' ? "config/#{service}_wrapper_test.yml" : ".#{service}_wrapper"
  return { config: config_file } if File.exist?(config_file)
  defaults
end
