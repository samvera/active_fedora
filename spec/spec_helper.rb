ENV["environment"] ||= 'test'
require "bundler/setup"

require 'simplecov'
require 'coveralls'

SimpleCov.start do
  add_filter "/spec/"
end

require 'active-fedora'
require 'rspec'
require 'rspec/its'
require 'equivalent-xml/rspec_matchers'
require 'logger'
require 'pry' unless ENV['TRAVIS']

ActiveFedora::Base.logger = Logger.new(STDERR)
ActiveFedora::Base.logger.level = Logger::WARN
# require 'http_logger'
# HttpLogger.logger = Logger.new(STDOUT)
# HttpLogger.ignore = [/localhost:8983\/solr/]
# HttpLogger.colorize = false
# HttpLogger.log_headers = true

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

$VERBOSE = nil

# This loads the Fedora and Solr config info from /config/fedora.yml
# You can load it from a different location by passing a file path as an argument.
def restore_spec_configuration
  ActiveFedora.init(fedora_config_path: File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))
end
restore_spec_configuration

require 'active_fedora/cleaner'
RSpec.configure do |config|
  # Stub out test stuff.
  config.before(:each) do
    begin
      ActiveFedora::Cleaner.clean!
    rescue Faraday::ConnectionFailed, RSolr::Error::ConnectionRefused => e
      $stderr.puts e.message
    end
  end

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'
  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
end

def fixture(file)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', file), 'rb')
end
