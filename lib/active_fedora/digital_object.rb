module ActiveFedora
  # Helps Rubydora create datastreams of the type defined by the ActiveFedora::Base#datastream_class_for_name
  class DigitalObject < Rubydora::DigitalObject
    attr_accessor :original_class
    
    def self.find(original_class, pid)
      obj = super(pid, RubydoraConnection.instance.connection)
      obj.original_class = original_class
      obj
    end

    # def datastreams
    #   @datastreams ||= begin
    #     h = Hash.new { |h,k| h[k] = datastream_object_for(k) }                

    #     begin
    #       datastreams_xml = repository.datastreams(:pid => pid)
    #       datastreams_xml.gsub! '<objectDatastreams', '<objectDatastreams xmlns="http://www.fedora.info/definitions/1/0/access/"' unless datastreams_xml =~ /xmlns=/
    #       doc = Nokogiri::XML(datastreams_xml)
    #       doc.xpath('//access:datastream', {'access' => "http://www.fedora.info/definitions/1/0/access/"}).each do |ds| 
    #         h[ds['dsid']] = datastream_object_for ds['dsid'] 
    #       end
    #     rescue RestClient::ResourceNotFound
    #     end

    #     h
    #   end
    # end


    def datastream_object_for dsid
      klass = original_class.datastream_class_for_name(dsid)
      klass.new self, dsid
    end
    
  end
end
