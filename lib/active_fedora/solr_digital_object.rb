module ActiveFedora
  class SolrDigitalObject
    include DigitalObject::DatastreamBootstrap
    extend Deprecation
    self.deprecation_horizon = 'active-fedora version 8.0.0'
    attr_reader :pid, :label, :state, :ownerId, :profile, :datastreams, :solr_doc
    attr_accessor :original_class
    def initialize(solr_doc, profile_hash, klass=ActiveFedora::Base)
      @solr_doc = solr_doc
      @pid = solr_doc[SOLR_DOCUMENT_ID]
      @profile = {}
      profile_hash.each_pair { |key,value| @profile[key] = value.to_s if key =~ /^obj/ }
      @profile['objCreateDate'] ||= Time.now.xmlschema
      @profile['objLastModDate'] ||= @profile['objCreateDate']

      @datastreams = {}
      
      dsids = profile_hash['datastreams'].keys
      self.original_class = klass
      missing = dsids - klass.ds_specs.keys
      missing.each do |dsid|
        #Initialize the datastreams that are in the solr document, but not found in the classes spec.
        mime_type = profile_hash['datastreams'][dsid]['dsMIME']
        ds_class = mime_type =~ /[\/\+]xml$/ ? OmDatastream : Datastream
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

    def fetch(field, default=[])
      attribute = original_class.defined_attributes[field]
      field_name = attribute.primary_solr_name
      raise KeyError, "Tried to fetch `#{field}' from solr, but it isn't indexed." unless field_name
      val = solr_doc.fetch field_name, default
      case attribute.type
      when :date
        val.is_a?(Array) ? val.map{|v| Date.parse v} : Date.parse(val)
      else
        val
      end
    end
    
    def new_record?
      false
    end
    alias new? new_record?
    deprecation_deprecate :new?

    def uri
      "solr:#{pid}"
    end

  end
end
