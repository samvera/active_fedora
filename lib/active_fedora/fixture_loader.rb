module ActiveFedora
  class FixtureLoader
    attr_accessor :path

    def initialize(path)
      self.path = path
    end 

    def filename_for_pid(pid)
      File.join(path, "#{pid.gsub(":","_")}.foxml.xml")
    end

    def self.delete(pid)
      begin
        ActiveFedora::Base.find(pid, cast: true).delete
        1
      rescue ActiveFedora::ObjectNotFoundError
        logger.debug "The object #{pid} has already been deleted (or was never created)."
        0
      rescue Errno::ECONNREFUSED => e
        logger.debug "Can't connect to Fedora! Are you sure jetty is running?"
       0
      end
    end

    def reload(pid)
      self.class.delete(pid)
      import_and_index(pid)
    end

    def import_and_index(pid)
      body = self.class.import_to_fedora(filename_for_pid(pid), pid)
      self.class.index(pid)
      body
    end

    def self.index(pid)
      ActiveFedora::Base.find(pid).update_index
    end

    def self.import_to_fedora(filename, pid='0')
      file = File.new(filename, "r")
      result = ActiveFedora::Base.connection_for_pid(pid).ingest(:file=>file.read)
      raise "Failed to ingest the fixture." unless result
      result.body
    end
  end
end
