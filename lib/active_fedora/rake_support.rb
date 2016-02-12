# Starts a fedora server and a solr server on a random port and then
# yields the passed block
def with_test_server
  return yield if ENV['SERVER_STARTED']

  ENV['SERVER_STARTED'] = 'true'

  # setting port: nil assigns a random port.
  solr_params = { port: nil, verbose: true, managed: true }
  fcrepo_params = { port: nil, verbose: true, managed: true,
                    enable_jms: false, fcrepo_home_dir: 'fcrepo4-test-data' }
  SolrWrapper.wrap(solr_params) do |solr|
    ENV['SOLR_TEST_PORT'] = solr.port
    solr.with_collection(name: 'hydra-test', dir: File.join(File.expand_path("../..", File.dirname(__FILE__)), "solr", "config")) do
      FcrepoWrapper.wrap(fcrepo_params) do |fcrepo|
        ENV['FCREPO_TEST_PORT'] = fcrepo.port
        yield
      end
    end
  end
  ENV['SERVER_STARTED'] = 'false'
end
