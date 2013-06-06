APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../")

require 'jettywrapper'

namespace :active_fedora do
  require 'active-fedora'

  # Use yard to build docs
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = APP_ROOT
    doc_destination = File.join(project_root, 'doc')

    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   [ '-', File.join(project_root, 'README.textile'), File.join(project_root,'CONSOLE_GETTING_STARTED.textile'), File.join(project_root,'NOKOGIRI_DATASTREAMS.textile') ]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end

require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:rspec) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
    spec.pattern += FileList['spec/*_spec.rb']
  end

  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.pattern = FileList['spec/**/*_spec.rb']
    spec.pattern += FileList['spec/*_spec.rb']
    spec.rcov = true
  end

  desc "Loads or refreshes the fixtures needed to run the tests"
  task :fixtures => :environment do
    ENV["pid"] = "test:fixture_mods_article1"
    Rake::Task["repo:refresh"].invoke
    ENV["pid"] = nil

    Rake::Task["repo:delete"].reenable
    Rake::Task["repo:load"].reenable
    Rake::Task["repo:refresh"].reenable

    ENV["pid"] = "test:fixture_mods_article2"
    Rake::Task["repo:refresh"].invoke
    ENV["pid"] = nil
  end

  desc "Copies the default SOLR config for the bundled Testing Server"
  task :configure_jetty do
    FileList['lib/generators/active_fedora/config/solr/templates/solr_conf/conf/*'].each do |f|  
      cp("#{f}", 'jetty/solr/development-core/conf/', :verbose => true)
      cp("#{f}", 'jetty/solr/test-core/conf/', :verbose => true)
    end
  end


desc "CI build"
task :ci do
  ENV['environment'] = "test"
  Rake::Task["active_fedora:configure_jetty"].invoke
  jetty_params = Jettywrapper.load_config
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['active_fedora:coverage'].invoke
  end
  raise "test failures: #{error}" if error
  # Only create documentation if the tests have passed
  Rake::Task["active_fedora:doc"].invoke
end

desc "Execute specs with coverage"
task :coverage do 
  # Put spec opts in a file named .rspec in root
  ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
  ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'

  Rake::Task["active_fedora:fixtures"].invoke
  Rake::Task["active_fedora:rspec"].invoke
end

end

