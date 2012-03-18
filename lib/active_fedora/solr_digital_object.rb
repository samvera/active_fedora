module ActiveFedora
  class SolrDigitalObject
    attr_reader :pid, :label, :state, :ownerId, :profile, :datastreams, :solr_doc
    
    def initialize(solr_doc, klass=ActiveFedora::Base)
      @solr_doc = solr_doc
      @pid = solr_doc[SOLR_DOCUMENT_ID]
      profile_attrs = solr_doc.keys.select { |k| k =~ /^objProfile_/ }
      @profile = {}
      profile_attrs.each do |key|
        attr_name = key.split(/_/)[1..-2].join('_')
        @profile[attr_name] = Array(solr_doc[key]).first.to_s
      end
      @profile['objCreateDate'] ||= Time.now.xmlschema
      @profile['objLastModDate'] ||= @profile['objCreateDate']

      @datastreams = {}
      
      dsids = @solr_doc.keys.collect { |k| k.scan(/^(.+)_dsProfile_/).flatten.first }.compact.uniq
      missing = dsids - klass.ds_specs.keys
      missing.each do |dsid|
        #Initialize the datastreams that are in the solr document, but not found in the classes spec.
        mime_key = ActiveFedora::SolrService.solr_name("#{dsid}_dsProfile_dsMIME",:symbol)
        mime_type = Array(@solr_doc[mime_key]).first
        ds_class = mime_type =~ /[\/\+]xml$/ ? NokogiriDatastream : Datastream
        @datastreams[dsid] = ds_class.new(self, dsid)
      end

      @label = @profile['objLabel']
      @state = @profile['objState']
      @ownerId = @profile['objOwnerId']
    end
    
    def freeze
      @finished = true
      @profile.freeze
      @datastreams.freeze
      class << self
        #Once this instance is frozen create a repository method just for this one instance.
        define_method :repository do
          ActiveFedora::Base.connection_for_pid(self.pid)
        end
      end
      self
    end
    
    def new?
      false
    end

  end
end
