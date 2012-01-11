module ActiveFedora
  module FixtureExporter

    def self.export_to_path(pid, path)
      foxml = export(pid)
      name = "#{pid.gsub(":","_")}.foxml.xml"
      filename = File.join(path, name)
      file = File.new(filename,"w")
      file.syswrite(foxml)
      filename
    end

    def self.export(pid)
      RubydoraConnection.instance.connection.export(pid)
    end


  end
end

