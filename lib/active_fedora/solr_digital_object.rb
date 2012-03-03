module ActiveFedora
  class SolrDigitalObject
    attr_reader :pid, :label, :state, :ownerId, :profile, :datastreams
    
    def initialize(solr_doc)
      @pid = solr_doc[SOLR_DOCUMENT_ID]
      profile_attrs = solr_doc.keys.select { |k| k =~ /^objProfile_/ }
      @profile = {}
      profile_attrs.each do |key|
        attr_name = key.split(/_/)[1..-2].join('_')
        @profile[attr_name] = solr_doc[key].to_s
      end
      @profile['objCreateDate'] ||= Time.now.xmlschema
      @profile['objLastModDate'] ||= @profile['objCreateDate']
      
      @datastreams = {}
      @label = @profile['objLabel']
      @state = @profile['objState']
      @ownerId = @profile['objOwnerId']
    end

    def freeze
      @profile.freeze
      @datastreams.freeze
      self
    end
    
    def new?
      false
    end

  end
end
