begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end
begin
  require 'spec/rake/spectask'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end

APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../")
require 'jettywrapper'

$: << 'lib'
# def jetty_params 
#   project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
#   {
#       :quiet => false,
#       :jetty_home => File.join(project_root,'jetty'),
#       :jetty_port => 8983,
#       :solr_home => File.expand_path(File.join(project_root,'jetty','solr')),
#       :fedora_home => File.expand_path(File.join(project_root,'jetty','fedora','default')),
#       :startup_wait=>30
#     }
# end

desc "Run active-fedora rspec tests"
task :spec do
  Rake::Task["active_fedora:rspec"].invoke
end

desc "Hudson build"
task :hudson do
  
  ENV['environment'] = "test"
  Rake::Task["active_fedora:doc"].invoke
  Rake::Task["active_fedora:configure_jetty"].invoke
  jetty_params = Jettywrapper.load_config
  error = Jettywrapper.wrap(jetty_params) do
    ENV["FEDORA_HOME"]=File.expand_path(File.join(File.dirname(__FILE__),'..','..','jetty','fedora','default'))
    Rake::Task["active_fedora:load_fixtures"].invoke
    Rake::Task["active_fedora:rspec"].invoke
  end
  raise "test failures: #{error}" if error
end

namespace :active_fedora do
  require 'lib/active-fedora'

  # Use yard to build docs
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
    doc_destination = File.join(project_root, 'doc')

    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   [ File.join(project_root, 'README.textile'),'-', File.join(project_root,'CONSOLE_GETTING_STARTED.textile'),'-', File.join(project_root,'NOKOGIRI_DATASTREAMS.textile') ]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end


  Spec::Rake::SpecTask.new(:rspec) do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts << ['--exclude', 'gems']
    t.rcov_opts << ['--exclude', 'spec']
  end

  task :refresh_fixtures do
    Rake::Task["active_fedora:clean_jetty"].invoke
    Rake::Task["active_fedora:load_fixtures"].invoke
  end

  task :clean_jetty do
    Dir.chdir("./jetty")
    system("git clean -f -d")
    system("git checkout .")
    Dir.chdir("..")
  end

  task :load_fixtures => :environment do
    require 'solrizer'
    require 'solrizer-fedora'
    require 'spec/samples/models/hydrangea_article'
    ENV["FEDORA_HOME"] ||= File.expand_path(File.join(File.dirname(__FILE__),'..','..','jetty','fedora','default'))
    retval = `$FEDORA_HOME/client/bin/fedora-ingest-demos.sh localhost 8983 fedoraAdmin fedoraAdmin http`
    puts "loaded demo objects #{retval}"
    ActiveFedora.init unless Thread.current[:repo]
    
    ENV["pid"] = "hydrangea:fixture_mods_article1"
    Rake::Task["af:refresh_fixture"].invoke
    ENV["pid"] = nil
  end

  desc "Copies the default SOLR config for the bundled Testing Server"
  task :configure_jetty do
    Rake::Task["active_fedora:clean_jetty"].invoke
    FileList['solr/conf/*'].each do |f|  
      cp("#{f}", 'jetty/solr/development-core/conf/', :verbose => true)
      cp("#{f}", 'jetty/solr/test-core/conf/', :verbose => true)
    end
  end
end

# Provides an :environment task for use while working within a working copy of active-fedora
# You should never load this rake file into any other application
desc 'Set up ActiveFedora environment.  !! Only for use while working within a working copy of active-fedora'
task :environment do
  puts "Initializing ActiveFedora Rake environment.  This should only be called when working within a workign copy of the active-fedora code."
  require 'spec/samples/models/hydrangea_article'
  require 'active_fedora/samples'
end
