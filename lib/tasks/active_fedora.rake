require "active-fedora"
require "active_support" # This is just to load ActiveSupport::CoreExtensions::String::Inflections

ZIP_FILE = 'https://github.com/projecthydra/hydra-jetty/archive/v5.2.0.zip'

namespace :repo do
  
  desc "Delete and re-import the object identified by pid" 
  task :refresh => [:delete,:load]
  
  desc "Delete the object identified by pid. Example: rake repo:delete pid=demo:12"
  task :delete => :environment do
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake repo:delete pid=demo:12"
    else
      pid = ENV["pid"]
      result = ActiveFedora::FixtureLoader.delete(pid)
      puts "Deleted '#{pid}' from #{ActiveFedora::Base.connection_for_pid(pid).client.url}" if result == 1
    end
  end
  
  desc "Delete a range of objects in a given namespace.  ie 'rake repo:delete_range namespace=demo start=22 stop=50' will delete demo:22 through demo:50"
  task :delete_range => :environment do |t, args|
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
      result = ActiveFedora::FixtureLoader.delete(pid)
      puts "Deleted '#{pid}' from #{ActiveFedora::Base.connection_for_pid(pid).client.url}" if result == 1
      i += 1
    end
  end

  desc "Export the object identified by pid into spec/fixtures. Example:rake repo:export pid=demo:12"
  task :export => :environment do
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake repo:export pid=demo:12"
    else
      pid = ENV["pid"]
      puts "Exporting '#{pid}' from #{ActiveFedora::Base.connection_for_pid(pid).client.url}"
      if !ENV["dir"].nil?
        dir = ENV["dir"]
      else
        dir = File.join('spec', 'fixtures')
      end
      filename = ActiveFedora::FixtureExporter.export_to_path(pid, dir)
      puts "The object has been saved as #{filename}" if filename
    end
  end
  
  desc "Load the object located at the provided path or identified by pid. Example: rake repo:load foxml=spec/fixtures/demo_12.foxml.xml"
  task :load => :environment do
    if !ENV["foxml"].nil? and File.file?(ENV["foxml"])
      filename = ENV["foxml"]
      pid = ActiveFedora::FixtureLoader.import_to_fedora(filename)
      ActiveFedora::FixtureLoader.index(pid)
    elsif !ENV["pid"].nil?
      pid = ENV["pid"]
      if !ENV["dir"].nil? and File.directory?(ENV["dir"])
       loader = ActiveFedora::FixtureLoader.new(ENV["dir"])
      else
       loader = ActiveFedora::FixtureLoader.new(File.join("spec", "fixtures"))
      end
      loader.import_and_index(pid)
    else
      puts "You must specify the foxml path or provide its pid.  Example: rake repo:load foxml=spec/fixtures/demo_12.foxml.xml"
    end
    puts "Loaded '#{pid}' into #{ActiveFedora::Base.connection_for_pid(pid).client.url}" if pid
  end


end

task :environment do
  # This task is overridden (chained) in hydra-head.
end

