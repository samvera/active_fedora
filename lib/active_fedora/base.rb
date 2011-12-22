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
    include RelationshipsHelper
    include SemanticNode
    include Relationships

    class_attribute  :ds_specs
    
    def self.inherited(p)
      # each subclass should get a copy of the parent's datastream definitions, it should not add to the parent's definition table.
      p.ds_specs = p.ds_specs.dup
      super
    end
    
    self.ds_specs = {'RELS-EXT'=> {:type=> ActiveFedora::RelsExtDatastream, :label=>"", :block=>nil}}

    
#TODO See if AF can run without these

    has_relationship "collection_members", :has_collection_member
    has_relationship "part_of", :is_part_of
    has_bidirectional_relationship "parts", :has_part, :is_part_of
    

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

    # Constructor. If +attrs+  does  not comtain +:pid+, we assume we're making a new one,
    # and call off to the Fedora Rest API for the next available Fedora pid, and mark as new object.
    # Also, if +attrs+ does not contain +:pid+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next pid available within
    # the given namespace.
    # 
    # If there is a pid, we're re-hydrating an existing object, and new object is false. Once the @inner_object is stored,
    # we configure any defined datastreams.
    def initialize(attrs = nil)
      attrs = {} if attrs.nil?
      attributes = attrs.dup
      @inner_object = attributes.delete(:inner_object)
      unless @inner_object
        if attributes[:pid]
          @inner_object = DigitalObject.find(self.class, attributes[:pid])
        else
          @inner_object = UnsavedDigitalObject.new(self.class, attributes.delete(:namespace))
          self.relationships_loaded = true
        end
      end
      load_datastreams

      [:pid, :new_object,:create_date, :modified_date].each { |k| attributes.delete(k)}
      self.attributes=attributes
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

    def self.method_missing (name, args)
      if name == :has_datastream
        ActiveSupport::Deprecation.warn("Deprecation: DatastreamCollections will not be included by default in the next version.   To use has_datastream add 'include ActiveFedora::DatastreamCollections' to your model")
        include DatastreamCollections
        has_datastream(args)
      else 
        super
      end

    end

    def method_missing(name, *args)
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

    ## Given a method name, return the best-guess dsid
    def corresponding_datastream_name(method_name)
      dsid = method_name.to_s
      return dsid if datastreams.has_key? dsid
      unescaped_name = method_name.to_s.gsub('_', '-')
      return unescaped_name if datastreams.has_key? unescaped_name
      nil
    end

    #Saves a Base object, and any dirty datastreams, then updates 
    #the Solr index for this object.
    def save

      # If it's a new object, set the conformsTo relationship for Fedora CMA
      if new_object? 
        result = create
      else
        result = update
      end
      self.update_index if @metadata_is_dirty == true && ENABLE_SOLR_UPDATES
      @metadata_is_dirty = false
      return result
    end

    def save!
      save
    end
    
    # Refreshes the object's info from Fedora
    # Note: Currently just registers any new datastreams that have appeared in fedora
    def refresh
#      inner_object.load_attributes_from_fedora
    end

    #Deletes a Base object, also deletes the info indexed in Solr, and 
    #the underlying inner_object.  If this object is held in any relationships (ie inbound relationships
    #outside of this object it will remove it from those items rels-ext as well
    def delete
      inbound_relationships(:objects).each_pair do |predicate, objects|
        objects.each do |obj|
          if obj.respond_to?(:remove_relationship)
            obj.remove_relationship(predicate,self)
            obj.save
          end 
        end
      end
      
      #Fedora::Repository.instance.delete(@inner_object)
      pid = self.pid ## cache so it's still available after delete
      begin
        @inner_object.delete
      rescue RestClient::ResourceNotFound =>e
        raise ObjectNotFoundError, "Unable to find #{pid} in the repository"
      end
      if ENABLE_SOLR_UPDATES
        ActiveFedora::SolrService.instance.conn.delete(pid) 
        # if defined?( Solrizer::Solrizer ) 
        #   solrizer = Solrizer::Solrizer.new
        #   solrizer.solrize_delete(pid)
        # end
      end
    end


    #
    # Datastream Management
    #
    
    # Returns all known datastreams for the object.  If the object has been 
    # saved to fedora, the persisted datastreams will be included.
    # Datastreams that have been modified in memory are given preference over 
    # the copy in Fedora.
    def datastreams
      @datastreams ||= DatastreamHash.new(self)
    end
  
    def datastreams_in_memory
      ActiveSupport::Deprecation.warn("ActiveFedora::Base.datastreams_in_memory has been deprecated.  Use #datastreams instead")
      datastreams
    end

    def configure_datastream(ds, ds_spec=nil)
      ds_spec ||= self.class.ds_specs[ds.instance_variable_get(:@dsid)]
      if ds_spec
        ds.model = self if ds_spec[:type] == RelsExtDatastream
        # If you called has_metadata with a block, pass the block into the Datastream class
        if ds_spec[:block].class == Proc
          ds_spec[:block].call(ds)
        end
      end
    end

    def datastream_from_spec(ds_spec, name)
      ds = ds_spec[:type].new(inner_object, name)
      ds.dsLabel = ds_spec[:label] if ds_spec[:label].present?
      ds.controlGroup = ds_spec[:control_group]
      additional_attributes_for_external_and_redirect_control_groups(ds, ds_spec)
      ds
    end

    def load_datastreams
      ds_specs = self.class.ds_specs.dup
      inner_object.datastreams.each do |dsid, ds|
        self.add_datastream(ds)
        configure_datastream(datastreams[dsid])
        ds_specs.delete(dsid)
      end
      ds_specs.each do |name,ds_spec|
        ds = datastream_from_spec(ds_spec, name)
        self.add_datastream(ds)
        configure_datastream(ds, ds_spec)
      end
    end      

    # Adds datastream to the object.  Saves the datastream to fedora upon adding.
    # If datastream does not have a DSID, a unique DSID is generated
    # :prefix option will set the prefix on auto-generated DSID
    # @return [String] dsid of the added datastream
    def add_datastream(datastream, opts={})
      if datastream.dsid == nil || datastream.dsid.empty?
        prefix = opts.has_key?(:prefix) ? opts[:prefix] : "DS"
        datastream.instance_variable_set :@dsid, generate_dsid(prefix)
      end
      datastreams[datastream.dsid] = datastream
      return datastream.dsid
    end

    def add(datastream) # :nodoc:
      warn "Warning: ActiveFedora::Base.add has been deprecated.  Use add_datastream"
      add_datastream(datastream)
    end
    
    #return all datastreams of type ActiveFedora::MetadataDatastream
    def metadata_streams
      results = []
      datastreams.each_value do |ds|
        if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::NokogiriDatastream)
          results << ds
        end
      end
      return results
    end
    
    #return all datastreams not of type ActiveFedora::MetadataDatastream 
    #(that aren't Dublin Core or RELS-EXT streams either)
    def file_streams
      results = []
      datastreams.each_value do |ds|
        if !ds.kind_of?(ActiveFedora::MetadataDatastream) 
          dsid = ds.dsid
          if dsid != "DC" && dsid != "RELS-EXT"
            results << ds
          end
        end
      end
      return results
    end
    
    # return a valid dsid that is not currently in use.  Uses a prefix (default "DS") and an auto-incrementing integer
    # Example: if there are already datastreams with IDs DS1 and DS2, this method will return DS3.  If you specify FOO as the prefix, it will return FOO1.
    def generate_dsid(prefix="DS")
      matches = datastreams.keys.map {|d| data = /^#{prefix}(\d+)$/.match(d); data && data[1].to_i}.compact
      val = matches.empty? ? 1 : matches.max + 1
      format_dsid(prefix, val)
    end
    
    ### Provided so that an application can override how generated pids are formatted (e.g DS01 instead of DS1)
    def format_dsid(prefix, suffix)
      sprintf("%s%i", prefix,suffix)
    end    

    # Return the Dublin Core (DC) Datastream. You can also get at this via 
    # the +datastreams["DC"]+.
    def dc
      #dc = REXML::Document.new(datastreams["DC"].content)
      return  datastreams["DC"] 
    end

    # Returns the RELS-EXT Datastream
    # Tries to grab from in-memory datastreams first
    # Failing that, attempts to load from Fedora and addst to in-memory datastreams
    # Failing that, creates a new RelsExtDatastream and adds it to the object
    def rels_ext
      if !datastreams.has_key?("RELS-EXT") 
        ds = ActiveFedora::RelsExtDatastream.new(@inner_object,'RELS-EXT')
        ds.model = self
        add_datastream(ds)
      end
      return datastreams["RELS-EXT"]
    end

    #
    # File Management
    #
    
    # Add the given file as a datastream in the object
    #
    # @param [File] file the file to add
    # @param [Hash] opts options: :dsid, :label, :mimeType, :prefix
    def add_file_datastream(file, opts={})
      label = opts.has_key?(:label) ? opts[:label] : ""
      attrs = {:dsLabel => label, :controlGroup => 'M', :blob => file, :prefix=>opts[:prefix]}
      if opts.has_key?(:mime_type)
        attrs.merge!({:mimeType=>opts[:mime_type]})
      elsif opts.has_key?(:mimeType)
        attrs.merge!({:mimeType=>opts[:mimeType]})
      elsif opts.has_key?(:content_type)
        attrs.merge!({:mimeType=>opts[:content_type]})
      end
      ds = create_datastream(ActiveFedora::Datastream, opts[:dsid], attrs)
      add_datastream(ds)
    end
    
    # List the objects that assert isPartOf pointing at this object _plus_ all objects that this object asserts hasPart for
    #   Note: Previous versions of ActiveFedora used hasCollectionMember to represent this type of relationship.  
    #   To accommodate this, until active-fedora-1.3, .file_assets will also return anything that this asserts hasCollectionMember for and will output a warning in the logs.
    #
    # @param [Hash] opts -- same options as auto-generated methods for relationships (ie. :response_format)
    # @return [Array of ActiveFedora objects, Array of PIDs, or Solr::Result] -- same options as auto-generated methods for relationships (ie. :response_format)
    def file_objects(opts={})
      cm_array = collection_members(:response_format=>:id_array)
      
      if !cm_array.empty?
        logger.warn "This object has collection member assertions.  hasCollectionMember will no longer be used to track file_object relationships after active_fedora 1.3.  Use isPartOf assertions in the RELS-EXT of child objects instead."
        if opts[:response_format] == :solr || opts[:response_format] == :load_from_solr
          logger.warn ":solr and :load_from_solr response formats for file_objects search only uses parts relationships (usage of hasCollectionMember is no longer supported)"
          result = parts(opts)
        else
          cm_result = collection_members(opts)
          parts_result = parts(opts)
          ary = cm_result+parts_result
          result = ary.uniq
        end
      else
        result = parts(opts)
      end
      return result
    end
    
    # Add the given obj as a child to the current object using an inbound is_part_of relationship
    #
    # @param [ActiveFedora::Base,String] obj the object or the pid of the object to add
    # @return [Boolean] whether saving the child object was successful
    # @example This will add an is_part_of relationship to the child_object's RELS-EXT datastream pointing at parent_object
    #   parent_object.file_objects_append(child_object)
    def file_objects_append(obj)
      # collection_members_append(obj)
      unless obj.kind_of? ActiveFedora::Base
        begin
          obj = ActiveFedora::Base.load_instance(obj)
        rescue ActiveFedora::ObjectNotFoundError
          "You must provide either an ActiveFedora object or a valid pid to add it as a file object.  You submitted #{obj.inspect}"
        end
      end
      obj.add_relationship(:is_part_of, self)
      obj.save
    end
    
    # Add the given obj as a collection member to the current object using an outbound has_collection_member relationship.
    #
    # @param [ActiveFedora::Base] obj the file to add
    # @return [ActiveFedora::Base] obj returns self
    # @example This will add a has_collection_member relationship to the parent_object's RELS-EXT datastream pointing at child_object
    #   parent_object.collection_members_append(child_object)
    def collection_members_append(obj)
      add_relationship(:has_collection_member, obj)
      return self
    end

    def collection_members_remove()
      # will rely on SemanticNode.remove_relationship once it is implemented
    end
    
    def create_datastream(type, dsid, opts={})
      dsid = generate_dsid(opts[:prefix] || "DS") if dsid == nil
      klass = type.kind_of?(Class) ? type : type.constantize
      raise ArgumentError, "Argument dsid must be of type string" unless dsid.kind_of?(String) || dsid.kind_of?(NilClass)
      ds = klass.new(inner_object, dsid)
      ds.mimeType = opts[:mimeType] 
      ds.controlGroup = opts[:controlGroup] 
      ds.dsLabel = opts[:dsLabel] 
      ds.dsLocation = opts[:dsLocation] 
      blob = opts[:blob] 
      if blob 
        if !ds.mimeType.present? 
          ##TODO, this is all done by rubydora -- remove
          ds.mimeType = blob.respond_to?(:content_type) ? blob.content_type : "application/octet-stream"
        end
        if !ds.dsLabel.present? && blob.respond_to?(:path)
          ds.dsLabel = File.basename(blob.path)
#          ds.dsLabel = blob.original_filename
        end
      end

#      blob = blob.read if blob.respond_to? :read
      ds.content = blob || "" 
      ds
    end


    # 
    # Relationships Management
    #
    
    # @return [Hash] relationships hash, as defined by SemanticNode
    # Rely on rels_ext datastream to track relationships array
    # Overrides accessor for relationships array used by SemanticNode.
    # If outbound_only is false, inbound relationships will be included.
    # def relationships(outbound_only=true)
    #   outbound_only ? rels_ext.relationships : rels_ext.relationships.merge(:inbound=>inbound_relationships)
    # end

    

    def inner_object # :nodoc
      @inner_object
    end

    #return the pid of the Fedora Object
    # if there is no fedora object (loaded from solr) get the instance var
    # TODO make inner_object a proxy that can hold the pid
    def pid
       @inner_object.pid
#      @inner_object ?  @inner_object.pid : @pid
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

    #return the error list of the inner object (unless it's a new object)
    def errors
      #@inner_object.errors
      []
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
      klass.new({:inner_object=>inner_object})
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
      obj = self.new({:pid=>solr_doc[SOLR_DOCUMENT_ID],:create_date=>create_date,:modified_date=>modified_date})
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

    # Updates Solr index with self.
    def update_index
      if defined?( Solrizer::Fedora::Solrizer ) 
        #logger.info("Trying to solrize pid: #{pid}")
        solrizer = Solrizer::Fedora::Solrizer.new
        solrizer.solrize( self )
      else
        #logger.info("Trying to update solr for pid: #{pid}")
        SolrService.instance.conn.update(self.to_solr)
      end
    end


    def update_attributes(properties)
      self.attributes=properties
      save
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
    
    # This can be overriden to assert a different model
    # It's normally called once in the lifecycle, by #create#
    def assert_content_model
      add_relationship(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(self.class))
    end

    private
    def configure_defined_datastreams
      if self.class.ds_specs
        self.class.ds_specs.each do |name,ds_config|
          if self.datastreams.has_key?(name)
            #attributes = self.datastreams[name].attributes
          else
            ds = ds_config[:type].new(inner_object, name)
            ds.model = self if ds_config[:type] == RelsExtDatastream
            ds.dsLabel = ds_config[:label] if ds_config[:label].present?
            ds.controlGroup = ds_config[:control_group]
            # If you called has_metadata with a block, pass the block into the Datastream class
            if ds_config[:block].class == Proc
              ds_config[:block].call(ds)
            end
            additional_attributes_for_external_and_redirect_control_groups(ds, ds_config)
            self.add_datastream(ds)
          end
        end
      end
    end


    # This method provides validation of proper options for control_group 'E' and 'R' and builds an attribute hash to be merged back into ds.attributes prior to saving
    #
    # @param [Object] ds The datastream
    # @param [Object] ds_config hash of options which may contain :disseminator and :url
    def additional_attributes_for_external_and_redirect_control_groups(ds,ds_config)
      if ds.controlGroup=='E'
        raise "Must supply either :disseminator or :url if you specify :control_group => 'E'" if (ds_config[:disseminator].empty? && ds_config[:url].empty?)
        if !ds_config[:disseminator].empty?
          ds.dsLocation= "#{RubydoraConnection.instance.options[:url]}/objects/#{pid}/methods/#{ds_config[:disseminator]}"
        elsif !ds_config[:url].empty?
          ds.dsLocation= ds_config[:url]
        end
      elsif ds.controlGroup=='R'
        raise "Must supply a :url if you specify :control_group => 'R'" if (ds_config[:url].empty?)
        ds.dsLocation= ds_config[:url]
      end
    end


    
    # Deals with preparing new object to be saved to Fedora, then pushes it and its datastreams into Fedora. 
    def create
      @inner_object = @inner_object.save #replace the unsaved digital object with a saved digital object
      assert_content_model
      @metadata_is_dirty = true
      update
    end
    
    # Pushes the object and all of its new or dirty datastreams into Fedora
    def update
      datastreams.each {|k, ds| ds.serialize! }
      @metadata_is_dirty = datastreams.any? {|k,ds| ds.changed? && (ds.class.included_modules.include?(ActiveFedora::MetadataDatastreamHelper) || ds.instance_of?(ActiveFedora::RelsExtDatastream))}

      result = @inner_object.save

      ### Rubydora re-inits the datastreams after a save, so ensure our copy stays in synch
      @inner_object.datastreams.each do |dsid, ds|
        datastreams[dsid] = ds
        ds.model = self if ds.kind_of? RelsExtDatastream
      end 
      refresh
      return !!result
    end

  end

  Base.class_eval do
    include Model
    include Solrizer::FieldNameMapper
    include Loggable
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    include Delegating
    include Associations
    include NestedAttributes
    include Reflection
    include NamedRelationships
#    include DatastreamCollections
  end

end
