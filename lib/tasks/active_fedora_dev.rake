APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../")

require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'

namespace :active_fedora do
  # Use yard to build docs
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = APP_ROOT
    doc_destination = File.join(project_root, 'doc')

    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) +
                   [ '-', File.join(project_root, 'README.md')]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.md']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end

  require 'rspec/core/rake_task'
  desc 'Run tests only'
  RSpec::Core::RakeTask.new(:rspec) do |spec|
    spec.rspec_opts = ['--backtrace'] if ENV['CI']
  end

  require 'rubocop/rake_task'
  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.rcov = true
  end

  desc "CI build"
  task :ci do
    Rake::Task['active_fedora:rubocop'].invoke unless ENV['NO_RUBOCOP']
    ENV['environment'] = "test"
    with_test_server do
      Rake::Task['active_fedora:coverage'].invoke
    end
  end

  desc "Execute specs with coverage"
  task :coverage do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'
    Rake::Task["active_fedora:spec"].invoke
  end

  desc "Execute specs with coverage"
  task :spec do
    with_test_server do
      Rake::Task["active_fedora:rspec"].invoke
    end
  end
end
