$: << 'lib'

desc "Hudson build"
task :hudson do
  require 'jettywrapper'
  if (ENV['RAILS_ENV'] == "test")
    Rake::Task["active_fedora:doc"].invoke
    Rake::Task["active_fedora:configure_jetty"].invoke
    jetty_params = {
      :quiet => false,
      :jetty_home => File.join(File.dirname(__FILE__),'..','jetty'),
      :jetty_port => 8983,
      :solr_home => File.expand_path(File.join(File.dirname(__FILE__),'..','jetty','solr')),
      :fedora_home => File.expand_path(File.join(File.dirname(__FILE__),'..','jetty','fedora','default')),
      :startup_wait=>30
    }
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["active_fedora:load_fixtures"].invoke
      Rake::Task["active_fedora:nokogiri_unit_tests"].invoke
      Rake::Task["active_fedora:nokogiri_integration_tests"].invoke
      ENV['HUDSON_BUILD'] = 'true'
      Rake::Task["active_fedora:rspec"].invoke
    end
    raise "test failures: #{error}" if error
  else
    system("rake hudson RAILS_ENV=test")
  end
end


namespace :active_fedora do
  require 'lib/active-fedora'

  # Use yard to build docs
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = File.expand_path("#{File.dirname(__FILE__)}/../")
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
    # removing because of en suite failures on hudson
    t.spec_files.delete 'spec/unit/nokogiri_datastream_spec.rb'
    t.spec_files.delete 'spec/integration/nokogiri_datastream_spec.rb'
    t.spec_files = ['spec/integration/mods_article_integration_spec.rb']
    t.rcov = true
    t.rcov_opts << "--exclude \"spec/* gems/*\" --rails"
  end

  Spec::Rake::SpecTask.new(:nokogiri_unit_tests) do |t|
    t.spec_files = ['spec/unit/nokogiri_datastream_spec.rb']
  end

  Spec::Rake::SpecTask.new(:nokogiri_integration_tests) do |t|
    t.spec_files = ['spec/integration/nokogiri_datastream_spec.rb']
    t.spec_files = ['spec/integration/mods_article_integration_spec.rb']
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
    ENV["FEDORA_HOME"]=File.expand_path(File.join(File.dirname(__FILE__),'..','jetty','fedora','default'))
    retval = `$FEDORA_HOME/client/bin/fedora-ingest-demos.sh localhost 8983 fedoraAdmin fedoraAdmin http`
    puts "loaded demo objects #{retval}"
    fixture = File.open(File.expand_path(File.join("spec","fixtures","hydrangea_fixture_mods_article1.foxml.xml")),"r")
    ActiveFedora.init unless Thread.current[:repo]
    result = foxml = Fedora::Repository.instance.ingest(fixture.read)
    if result
      solrizer = Solrizer::Fedora::Solrizer.new
      solrizer.solrize "hydrangea:fixture_mods_article1"
    end
    #retval = `$FEDORA_HOME/client/bin/fedora-ingest.sh f #{fixture} info:fedora/fedora-system:FOXML-1.1 localhost:8983 fedoraAdmin fedoraAdmin http`
    puts "Loaded #{fixture}:  #{retval}"
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
  # $:.unshift(File.dirname(__FILE__) + '/../lib')
  # Dir[File.join(File.dirname(__FILE__)+'/../lib/')+'**/*.rb'].each{|x| require x}
end
