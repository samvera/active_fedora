module ActiveFedora
  class SolrDigitalObject
    PROFILE_ATTRS = ["objCreateDate", "objLastModDate", "objState", "objOwnerId", "objDissIndexViewURL", "objLabel", "objItemIndexViewURL"]
    attr_reader :pid, :label, :state, :ownerId, :profile, :datastreams
    attr_accessor :repository
    
    def initialize(solr_doc)
      @profile = Hash[PROFILE_ATTRS.collect do |key|
        [key, solr_doc[ActiveFedora::SolrService.solr_name(key.underscore.to_sym, key =~ /Date$/ ? :date : :string)].to_s]
      end]
      @profile['objCreateDate'] ||= Time.now.xmlschema
      @profile['objLastModDate'] ||= self.attributes['objCreateDate']
      
      @datastreams = {}
      @label = @profile['objLabel']
      @state = @profile['objState']
      @ownerId = @profile['objOwnerId']
      @pid = solr_doc[SOLR_DOCUMENT_ID]
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
