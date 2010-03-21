module ActiveFedora
  
  #
  # This is a module replacing the ActiveFedora::Base class.
  #
  module FedoraObject
    def initialize
      @inner_object = Fedora::FedoraObject.new
      Fedora::Repository.instance.save @inner_object
    end

    def save
      Fedora::Repository.instance.save(@inner_object)
    end

    def delete
      Fedora::Repository.instance.delete(@inner_object)
    end

    def datastreams
      datastreams = {}
      self.datastreams_xml['datastream'].each do |ds|
        ds.merge!({:pid => self.pid, :dsID => ds["dsid"]})
        datastreams.merge!({ds["dsid"] => ActiveFedora::Datastream.new(ds)})
      end
      return datastreams
    end

    def datastreams_xml
      datastreams_xml = XmlSimple.xml_in(Fedora::Repository.instance.fetch_custom(self.pid, :datastreams))
    end

    # Adds datastream to the object.  Saves the datastream to fedora upon adding.
    def add_datastream(datastream)
      datastream.pid = self.pid
      datastream.save
    end

    # DC Datastream
    def dc
      #dc = REXML::Document.new(datastreams["DC"].content)
      return datastreams["DC"]
    end

    # RELS-EXT Datastream
    def rels_ext
      if !datastreams.has_key?("RELS-EXT")
        add(ActiveFedora::RelsExtDatastream.new)
      end
        
      return datastreams["RELS-EXT"]
    end

    def inner_object
      @inner_object
    end

    def pid
      @inner_object.pid
    end

    def state
      @inner_object.state
    end

    def owner_id
      @inner_object.owner_id
    end

    def errors
      @inner_object.errors
    end

  end



end
