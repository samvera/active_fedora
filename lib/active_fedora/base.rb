require "solrizer"
require 'nokogiri'
require "loggable"
require 'active_fedora/datastream_hash'


SOLR_DOCUMENT_ID = "id" unless (defined?(SOLR_DOCUMENT_ID) && !SOLR_DOCUMENT_ID.nil?)
ENABLE_SOLR_UPDATES = true unless defined?(ENABLE_SOLR_UPDATES)

module ActiveFedora
  
  # This class ties together many of the lower-level modules, and
  # implements something akin to an ActiveRecord-alike interface to
  # fedora. If you want to represent a fedora object in the ruby
  # space, this is the class you want to extend.
  #
  # =The Basics
  #   class Oralhistory < ActiveFedora::Base
  #     has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
  #       m.field "narrator",  :string
  #       m.field "narrator",  :text
  #     end
  #   end
  #
  # The above example creates a FedoraObject with a metadata datastream named "properties", which is composed of a 
  # narrator and bio field.
  #
  # Datastreams defined with +has_metadata+ are accessed via the +datastreams+ member hash.
  #
  # =Implementation
  # This class is really a facade for a basic Fedora::FedoraObject, which is stored internally.
  class Base
    include SemanticNode


    def self.method_missing (name, *args)
      if [:has_relationship, :has_bidirectional_relationship, :register_relationship_desc].include? name 
        ActiveSupport::Deprecation.warn("Deprecation: Relationships will not be included by default in the next version.   To use #{name} add 'include ActiveFedora::Relationships' to your model")
        include Relationships
        send name, *args
      elsif name == :has_datastream
        ActiveSupport::Deprecation.warn("Deprecation: DatastreamCollections will not be included by default in the next version.   To use has_datastream add 'include ActiveFedora::DatastreamCollections' to your model")
        include DatastreamCollections
        has_datastream(*args)
      else 
        super
      end
    end


    def method_missing(name, *args)
      if [:collection_members, :part_of, :parts, :part_of_append, :file_objects].include? name 
        ActiveSupport::Deprecation.warn("Deprecation: FileManagement will not be included by default in the next version.   To use #{name} add 'include ActiveFedora::FileManagement' to your model")
        self.class.send :include, FileManagement
        send name, *args
      else 
        dsid = corresponding_datastream_name(name)
        if dsid
          ### Create and invoke a proxy method 
          self.class.send :define_method, name do
              datastreams[dsid]
          end
          self.send(name)
        else 
          super
        end
      end
    end


    # class_attribute  :ds_specs
    # 
    # def self.inherited(p)
    #   # each subclass should get a copy of the parent's datastream definitions, it should not add to the parent's definition table.
    #   p.ds_specs = p.ds_specs.dup
    #   super
    # end
    # 
    # self.ds_specs = {'RELS-EXT'=> {:type=> ActiveFedora::RelsExtDatastream, :label=>"", :label=>"Fedora Object-to-Object Relationship Metadata", :control_group=>'X', :block=>nil}}

    # Has this object been saved?
    def new_object?
      inner_object.new?
    end
    
    def new_object=(bool)
      ActiveSupport::Deprecation.warn("ActiveFedora::Base.new_object= has been deprecated and nolonger has any effect")
    end

    ## Required by associations
    def new_record?
      self.new_object?
    end

    def persisted?
      !new_object?
    end

    def attributes=(properties)
      properties.each do |k, v|
        respond_to?(:"#{k}=") ? send(:"#{k}=", v) : raise(UnknownAttributeError, "unknown attribute: #{k}")
      end
    end

    # Constructor.  You may supply a custom +:pid+, or we call the Fedora Rest API for the
    # next available Fedora pid, and mark as new object.
    # Also, if +attrs+ does not contain +:pid+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next pid available within
    # the given namespace.
    def initialize(attrs = nil)
      attrs = {} if attrs.nil?
      attributes = attrs.dup
      @inner_object = UnsavedDigitalObject.new(self.class, attributes.delete(:namespace), attributes.delete(:pid))
      self.relationships_loaded = true
      load_datastreams

      [:new_object,:create_date, :modified_date].each { |k| attributes.delete(k)}
      self.attributes=attributes
      run_callbacks :initialize
    end


    # Initialize an empty model object and set the +inner_obj+
    # example:
    #
    #   class Post < ActiveFedora::Base
    #     has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream
    #   end
    #
    #   post = Post.allocate
    #   post.init_with(DigitalObject.find(pid))
    #   post.properties.title # => 'hello world'
    def init_with(inner_obj)
      @inner_object = inner_obj
      unless @inner_object.is_a? SolrDigitalObject
        ## Replace existing unchanged datastreams with the definitions found in this class
        @inner_object.original_class = self.class
        ds_specs.keys.each do |key|
          @inner_object.datastreams.delete(key) unless @inner_object.datastreams[key].changed.include?(:content)
        end
      end
      load_datastreams
      run_callbacks :find
      run_callbacks :initialize
      self
    end

    def self.datastream_class_for_name(dsid)
      ds_specs[dsid] ? ds_specs[dsid][:type] : ActiveFedora::Datastream
    end

    #This method is used to specify the details of a datastream. 
    #args must include :name. Note that this method doesn't actually
    #execute the block, but stores it at the class level, to be executed
    #by any future instantiations.
    def self.has_metadata(args, &block)
      ds_specs[args[:name]]= {:type => args[:type], :label =>  args.fetch(:label,""), :control_group => args.fetch(:control_group,"X"), :disseminator => args.fetch(:disseminator,""), :url => args.fetch(:url,""),:block => block}
    end

    def self.create(args = {})
      obj = self.new(args)
      obj.save
      obj
    end

    def inner_object # :nodoc
      @inner_object
    end

    #return the pid of the Fedora Object
    # if there is no fedora object (loaded from solr) get the instance var
    # TODO make inner_object a proxy that can hold the pid
    def pid
       @inner_object.pid
    end


    def id   ### Needed for the nested form helper
      self.pid
    end
    
    def to_key
      persisted? ? [pid] : nil
    end

    #return the internal fedora URI
    def internal_uri
      "info:fedora/#{pid}"
    end
    
    #return the state of the inner object
    def state 
      @inner_object.state
    end

    #return the owner id
    def owner_id
      @inner_object.ownerId
    end
    
    def owner_id=(owner_id)
      @inner_object.ownerId=(owner_id)
    end

    #return the create_date of the inner object (unless it's a new object)
    def create_date
      @inner_object.new? ? Time.now : @inner_object.profile["objCreateDate"]
    end

    #return the modification date of the inner object (unless it's a new object)
    def modified_date
      @inner_object.new? ? Time.now : @inner_object.profile["objLastModDate"]
    end

    #return the label of the inner object (unless it's a new object)
    def label
      @inner_object.label
    end
    
    def label=(new_label)
      @inner_object.label = new_label
    end

    #Return a hash of all available metadata fields for all 
    #ActiveFedora::MetadataDatastream datastreams, as well as 
    #system_create_date, system_modified_date, active_fedora_model_field, 
    #and the object id.
    def fields
      fields = {:id => {:values => [pid]}, :system_create_date => {:values => [self.create_date], :type=>:date}, :system_modified_date => {:values => [self.modified_date], :type=>:date}, :active_fedora_model => {:values => [self.class.inspect], :type=>:symbol}}
      datastreams.values.each do |ds|        
        fields.merge!(ds.fields) if ds.kind_of?(ActiveFedora::MetadataDatastream)
      end
      return fields
    end
    
    #Returns the xml version of this object as a string.
    def to_xml(xml=Nokogiri::XML::Document.parse("<xml><fields/><content/></xml>"))
      fields_xml = xml.xpath('//fields').first
      builder = Nokogiri::XML::Builder.with(fields_xml) do |fields_xml|
        fields_xml.id_ pid
        fields_xml.system_create_date self.create_date
        fields_xml.system_modified_date self.modified_date
        fields_xml.active_fedora_model self.class.inspect
      end
      
      # {:id => pid, :system_create_date => self.create_date, :system_modified_date => self.modified_date, :active_fedora_model => self.class.inspect}.each_pair do |attribute_name, value|
      #   el = REXML::Element.new(attribute_name.to_s)
      #   el.text = value
      #   fields_xml << el
      # end
      
      datastreams.each_value do |ds|  
        ds.to_xml(fields_xml) if ds.class.included_modules.include?(ActiveFedora::MetadataDatastreamHelper) || ds.kind_of?(ActiveFedora::RelsExtDatastream)
      end
      return xml.to_s
    end

    def ==(comparison_object)
         comparison_object.equal?(self) ||
           (comparison_object.instance_of?(self.class) &&
             comparison_object.pid == pid &&
             !comparison_object.new_record?)
    end
  
    def inspect
      "#<#{self.class}:#{self.hash} @pid=\"#{pid}\" >"
    end

    # Return a Hash representation of this object where keys in the hash are appropriate Solr field names.
    # @param [Hash] solr_doc (optional) Hash to insert the fields into
    # @param [Hash] opts (optional) 
    # If opts[:model_only] == true, the base object metadata and the RELS-EXT datastream will be omitted.  This is mainly to support shelver, which calls .to_solr for each model an object subscribes to. 
    def to_solr(solr_doc = Hash.new, opts={})
      unless opts[:model_only]
        solr_doc.merge!(SOLR_DOCUMENT_ID.to_sym => pid, ActiveFedora::SolrService.solr_name(:system_create, :date) => self.create_date, ActiveFedora::SolrService.solr_name(:system_modified, :date) => self.modified_date, ActiveFedora::SolrService.solr_name(:active_fedora_model, :symbol) => self.class.inspect)
      end
      datastreams.each_value do |ds|
        ds.ensure_xml_loaded if ds.respond_to? :ensure_xml_loaded  ### Can't put this in the model because it's often implemented in Solrizer::XML::TerminologyBasedSolrizer 
        solr_doc = ds.to_solr(solr_doc) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::NokogiriDatastream) 
      end
      solr_doc = solrize_relationships(solr_doc) unless opts[:model_only]
      begin
        #logger.info("PID: '#{pid}' solr_doc put into solr: #{solr_doc.inspect}")
      rescue
        logger.info("Error encountered trying to output solr_doc details for pid: #{pid}")
      end
      return solr_doc
    end

    # Serialize the datastream's RDF relationships to solr
    # @param [Hash] solr_doc @deafult an empty Hash
    def solrize_relationships(solr_doc = Hash.new)
      relationships.each_statement do |statement|
        predicate = RelsExtDatastream.short_predicate(statement.predicate)
        literal = statement.object.kind_of?(RDF::Literal)
        val = literal ? statement.object.value : statement.object.to_str
        ::Solrizer::Extractor.insert_solr_field_value(solr_doc, solr_name(predicate, :symbol), val )
      end
      return solr_doc
    end

    
    # ** EXPERIMENTAL **
    # This method adapts the inner_object to a new ActiveFedora::Base implementation
    # This is intended to minimize redundant interactions with Fedora
    def adapt_to(klass)
      unless klass.ancestors.include? ActiveFedora::Base
        raise "Cannot adapt #{self.class.name} to #{klass.name}: Not a ActiveFedora::Base subclass"
      end
      klass.allocate.init_with(inner_object)
    end
    # ** EXPERIMENTAL **
    #
    # This method can be used instead of ActiveFedora::Model::ClassMethods.load_instance.  
    # It works similarly except it populates an object from Solr instead of Fedora.
    # It is most useful for objects used in read-only displays in order to speed up loading time.  If only
    # a pid is passed in it will query solr for a corresponding solr document and then use it
    # to populate this object.
    # 
    # If a value is passed in for optional parameter solr_doc it will not query solr again and just use the
    # one passed to populate the object.
    #
    # It will anything stored within solr such as metadata and relationships.  Non-metadata datastreams will not
    # be loaded and if needed you should use load_instance instead.
    def self.load_instance_from_solr(pid,solr_doc=nil)
      if solr_doc.nil?
        result = find_by_solr(pid)
        raise "Object #{pid} not found in solr" if result.nil?
        solr_doc = result.hits.first
        #double check pid and id in record match
        raise "Object #{pid} not found in Solr" unless !result.nil? && !solr_doc.nil? && pid == solr_doc[SOLR_DOCUMENT_ID]
      else
        raise "Solr document record id and pid do not match" unless pid == solr_doc[SOLR_DOCUMENT_ID]
      end
     
      create_date = solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date)].nil? ? solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date).to_s] : solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date)]
      modified_date = solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date)].nil? ? solr_doc[ActiveFedora::SolrService.solr_name(:system_modified, :date).to_s] : solr_doc[ActiveFedora::SolrService.solr_name(:system_modified, :date)]
      obj = self.allocate.init_with(SolrDigitalObject.new(:pid=>solr_doc[SOLR_DOCUMENT_ID],:create_date=>create_date,:modified_date=>modified_date))
      #set by default to load any dependent relationship objects from solr as well
      #need to call rels_ext once so it exists when iterating over datastreams
      obj.rels_ext
      obj.datastreams.each_value do |ds|
        if ds.respond_to?(:from_solr)
          ds.from_solr(solr_doc) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::NokogiriDatastream) || ( ds.kind_of?(ActiveFedora::RelsExtDatastream))
        end
      end
      obj
    end

    # A convenience method  for updating indexed attributes.  The passed in hash
    # must look like this : 
    #   {{:name=>{"0"=>"a","1"=>"b"}}
    #
    # This will result in any datastream field of name :name having the value [a,b]
    #
    # An index of -1 will insert a new value. any existing value at the relevant index 
    # will be overwritten.
    #
    # As in update_attributes, this overwrites _all_ available fields by default.
    #
    # If you want to specify which datastream(s) to update,
    # use the :datastreams argument like so:
    #  m.update_attributes({"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}, :datastreams=>"my_ds")
    # or
    #  m.update_attributes({"fubar"=>{"-1"=>"mork", "0"=>"york", "1"=>"mangle"}}, :datastreams=>["my_ds", "my_other_ds"])
    #
    def update_indexed_attributes(params={}, opts={})
      if ds = opts[:datastreams]
        ds_array = []
        ds = [ds] unless ds.respond_to? :each
        ds.each do |dsname|
          ds_array << datastreams[dsname]
        end
      else
        ds_array = metadata_streams
      end
      result = {}
      ds_array.each do |d|
        result[d.dsid] = d.update_indexed_attributes(params,opts)
      end
      return result
    end
    
    # Updates the attributes for each datastream named in the params Hash
    # @param [Hash] params A Hash whose keys correspond to datastream ids and whose values are appropriate Hashes to submit to update_indexed_attributes on that datastream
    # @param [Hash] opts (currently ignored.)
    # @example Update the descMetadata and properties datastreams with new values
    #   article = HydrangeaArticle.new
    #   ds_values_hash = {
    #     "descMetadata"=>{ [{:person=>0}, :role]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} },
    #     "properties"=>{ "notes"=>"foo" }
    #   }
    #   article.update_datastream_attributes( ds_values_hash )
    def update_datastream_attributes(params={}, opts={})
      result = params.dup
      params.each_pair do |dsid, ds_params| 
        if datastreams.include?(dsid)
          result[dsid] = datastreams[dsid].update_indexed_attributes(ds_params)
        else
          result.delete(dsid)
        end
      end
      return result
    end
    
    def get_values_from_datastream(dsid,field_key,default=[])
      if datastreams.include?(dsid)
        return datastreams[dsid].get_values(field_key,default)
      else
        return nil
      end
    end
    
    def self.pids_from_uris(uris) 
      if uris.class == String
        return uris.gsub("info:fedora/", "")
      elsif uris.class == Array
        arr = []
        uris.each do |uri|
          arr << uri.gsub("info:fedora/", "")
        end
        return arr
      end
    end
    
  end

  Base.class_eval do
    include ActiveFedora::Persistence
    include Model
    include Solrizer::FieldNameMapper
    include Loggable
    include ActiveModel::Conversion
    include Validations
    include Callbacks
    include Datastreams
    extend ActiveModel::Naming
    include Delegating
    include Associations
    include NestedAttributes
    include Reflection
    include NamedRelationships
  end

end
