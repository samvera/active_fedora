require "active-fedora"
require "solrizer-fedora"
require "active_support" # This is just to load ActiveSupport::CoreExtensions::String::Inflections
namespace :repo do
  
  desc "Delete and re-import the object identified by pid" 
  task :refresh => [:delete,:load]
  
  desc "Delete the object identified by pid. Example: rake repo:delete pid=demo:12"
  task :delete => :init do
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake repo:delete pid=demo:12"
    else
      pid = ENV["pid"]
      begin
        ActiveFedora::Base.load_instance(pid).delete
      rescue ActiveFedora::ObjectNotFoundError
        puts "The object #{pid} has already been deleted (or was never created)."
      rescue Errno::ECONNREFUSED => e
        puts "Can't connect to Fedora! Are you sure jetty is running?"
      end
      puts "Deleted '#{pid}' from #{ActiveFedora::Base.connection_for_pid(pid).client.url}"
    end
  end
  
  desc "Delete a range of objects in a given namespace.  ie 'rake repo:delete_range namespace=demo start=22 stop=50' will delete demo:22 through demo:50"
  task :delete_range => :init do |t, args|
    namespace = ENV["namespace"]
    start_point = ENV["start"].to_i
    stop_point = ENV["stop"].to_i
    unless start_point <= stop_point 
      raise StandardError "start point must be less that end point."
    end
    puts "Deleting #{stop_point - start_point + 1} objects from #{namespace}:#{start_point.to_s} to #{namespace}:#{stop_point.to_s}"
    i = start_point
    while i <= stop_point do
      pid = namespace + ":" + i.to_s
      begin
        ActiveFedora::Base.load_instance(pid).delete
      rescue ActiveFedora::ObjectNotFoundError
        # The object has already been deleted (or was never created).  Do nothing.
      end
      puts "Deleted '#{pid}' from #{ActiveFedora::Base.connection_for_pid(pid).client.url}"
      i += 1
    end
  end

  desc "Export the object identified by pid into spec/fixtures. Example:rake repo:export pid=demo:12"
  task :export => :init do
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake repo:export pid=demo:12"
    else
      pid = ENV["pid"]
      puts "Exporting '#{pid}' from #{ActiveFedora::Base.connection_for_pid(pid).client.url}"
      if !ENV["path"].nil?
        path = ENV["path"]
      else
        path = File.join('spec', 'fixtures')
      end
      filename = ActiveFedora::FixtureExporter.export_to_path(pid, path)
      puts "The object has been saved as #{filename}"
    end
  end
  
  desc "Load the object located at the provided path or identified by pid. Example: rake repo:load path=spec/fixtures/demo_12.foxml.xml"
  task :load => :init do
    if !ENV["path"].nil? and File.file?(ENV["path"])
      filename = ENV["path"]
    elsif !ENV["pid"].nil?
      pid = ENV["pid"]
      if !ENV["path"].nil? and File.directory?(ENV["path"])
        filename = File.join(ENV["path"], "#{pid.gsub(":","_")}.foxml.xml")
      else
        filename = File.join("spec","fixtures","#{pid.gsub(":","_")}.foxml.xml")
      end
    else
      puts "You must specify a path to the object or provide its pid.  Example: rake repo:load path=spec/fixtures/demo_12.foxml.xml"
    end
    
    if !filename.nil?
      puts "Loading '#{filename}' in #{ActiveFedora::Base.connection_for_pid(pid).client.url}"
      file = File.new(filename, "r")
      result = ActiveFedora::Base.connection_for_pid(pid).ingest(:file=>file.read)
      if result
        puts "The object has been loaded as #{result.body}"
      	if pid.nil?
          pid = result.body
        end
        solrizer = Solrizer::Fedora::Solrizer.new 
        solrizer.solrize(pid) 
      else
        puts "Failed to load the object."
      end
    end    
    
  end

  
  desc "Init ActiveFedora configuration" 
  task :init do
    if !ENV["environment"].nil? 
      RAILS_ENV = ENV["environment"]
    end
    # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
    ActiveFedora.init unless Thread.current[:repo]  
  end

end
