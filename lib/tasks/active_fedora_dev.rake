# frozen_string_literal: true
require 'active_fedora/rake_support'
require 'yard'
require 'yard/rake/yardoc_task'
require 'rspec/core/rake_task'

project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
doc_destination = File.join(project_root, 'doc')

namespace :active_fedora do
  # Use yard to build docs
  begin
    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) +
                   ['-', File.join(project_root, 'README.md')]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.md']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task doc: :environment do
      abort "Please install the YARD gem to generate rdoc."
    end
  end

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

  desc "Execute specs with coverage"
  task coverage: :environment do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'
    Rake::Task["active_fedora:spec"].invoke
  end
end
