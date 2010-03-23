require 'util/class_level_inheritable_attributes'
require 'active_fedora/model'
require 'active_fedora/semantic_node'

SOLR_DOCUMENT_ID = "id" unless defined?(SOLR_DOCUMENT_ID)
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
    include MediaShelfClassLevelInheritableAttributes
    ms_inheritable_attributes  :ds_specs
    include Model
    include SemanticNode
    include SolrMapper

    has_relationship "collection_members", :has_collection_member
    

    # Has this object been saved?
    def new_object?
      @new_object
    end
    
    def new_object=(bool)
      @new_object = bool
      inner_object.new_object = bool
    end
    
    # Constructor. If +attrs+  does  not comtain +:pid+, we assume we're making a new one,
    # and call off to the Fedora Rest API for the next available Fedora pid, and mark as new object.
    # 
    # If there is a pid, we're re-hydrating an existing object, and new object is false. Once the @inner_object is stored,
    # we configure any defined datastreams.
    def initialize(attrs = {})
      unless attrs[:pid]
        attrs = attrs.merge!({:pid=>Fedora::Repository.instance.nextid})  
        @new_object=true
      else
        @new_object = attrs[:new_object] == false ? false : true
      end
      @inner_object = Fedora::FedoraObject.new(attrs)
      @datastreams = {}
      configure_defined_datastreams
    end

    #This method is used to specify the details of a datastream. 
    #args must include :name. Note that this method doesn't actually
    #execute the block, but stores it at the class level, to be executed
    #by any future instantiations.
    def self.has_metadata(args, &block)
      @ds_specs ||= Hash.new
      @ds_specs[args[:name]]= [args[:type], block]
    end

    #Saves a Base object, and any dirty datastreams, then updates 
    #the Solr index for this object.
    def save
      #@metadata_is_dirty = false
      # If it's a new object, set the conformsTo relationship for Fedora CMA
      if new_object? 
        result = create
      else
        result = update
      end
      @new_object = false
      self.update_index if @metadata_is_dirty == true && ENABLE_SOLR_UPDATES
      @metadata_is_dirty == false
      return result
    end
    
    # Refreshes the object's info from Fedora
    # Note: Currently just registers any new datastreams that have appeared in fedora
    def refresh
      inner_object.load_attributes_from_fedora
      @datastreams = datastreams_in_fedora.merge(datastreams_in_memory)
    end

    #Deletes a Base object, also deletes the info indexed in Solr, and 
    #the underlying inner_object.
    def delete
      Fedora::Repository.instance.delete(@inner_object)
      escaped_pid = self.pid.gsub(/(:)/, '\\:')
      SolrService.instance.conn.delete(escaped_pid) if ENABLE_SOLR_UPDATES 
    end


    #
    # Datastream Management
    #
    
    # Returns all known datastreams for the object.  If the object has been 
    # saved to fedora, the persisted datastreams will be included.
    # Datastreams that have been modified in memory are given preference over 
    # the copy in Fedora.
    def datastreams
      if @new_object
        @datastreams = datastreams_in_memory
      else
        @datastreams = (@datastreams == {}) ? datastreams_in_fedora : datastreams_in_memory
        #@datastreams = datastreams_in_fedora.merge(datastreams_in_memory)
      end

    end

    def datastreams_in_fedora #:nodoc:
      mds = {}
      self.datastreams_xml['datastream'].each do |ds|
        ds.merge!({:pid => self.pid, :dsID => ds["dsid"], :dsLabel => ds["label"]})
        if ds["dsid"] == "RELS-EXT" 
          mds.merge!({ds["dsid"] => ActiveFedora::RelsExtDatastream.new(ds)})
        else
          mds.merge!({ds["dsid"] => ActiveFedora::Datastream.new(ds)})
        end
        mds[ds["dsid"]].new_object = false
      end
      mds
    end

    def datastreams_in_memory #:ndoc:
      @datastreams ||= Hash.new
    end

    #return the datastream xml representation direclty from Fedora
    def datastreams_xml
      datastreams_xml = XmlSimple.xml_in(Fedora::Repository.instance.fetch_custom(self.pid, :datastreams))
    end

    # Adds datastream to the object.  Saves the datastream to fedora upon adding.
    # If datastream does not have a DSID, a unique DSID is generated
    # :prefix option will set the prefix on auto-generated DSID
    # @returns DSID of the added datastream
    def add_datastream(datastream, opts={})
      datastream.pid = self.pid
      if datastream.dsid == nil || datastream.dsid.empty?
        prefix = opts.has_key?(:prefix) ? opts[:prefix] : "DS"
        datastream.dsid = generate_dsid(prefix)
      end
      datastreams[datastream.dsid] = datastream
      return datastream.dsid
    end
    def add(datastream) # :nodoc:
      warn "Warning: ActiveFedora::Base.add has been deprected.  Use add_datastream"
      add_datastream(datastream)
    end
    
    #return all datastreams of type ActiveFedora::MetadataDatastream
    def metadata_streams
      results = []
      datastreams.each_value do |ds|
        if ds.kind_of?(ActiveFedora::MetadataDatastream) 
          results<<ds
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
            results<<ds
          end
        end
      end
      return results
    end
    
    # return a valid dsid that is not currently in use.  Uses a prefix (default "DS") and an auto-incrementing integer
    # Example: if there are already datastreams with IDs DS1 and DS2, this method will return DS3.  If you specify FOO as the prefix, it will return FOO1.
    def generate_dsid(prefix="DS")
      keys = datastreams.keys
      next_index = keys.select {|v| v =~ /(#{prefix}\d*$)/}.length + 1
      new_dsid = prefix.to_s + next_index.to_s
      # while keys.include?(new_dsid)
      #         next_index += 1
      #         new_dsid = prefix.to_s + rand(range).to_s
      #       end
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
        add_datastream(ActiveFedora::RelsExtDatastream.new)
      end
      return datastreams["RELS-EXT"]
    end

    #
    # File Management
    #
    
    def add_file_datastream(file, opts={})
      label = opts.has_key?(:label) ? opts[:label] : ""
      ds = ActiveFedora::Datastream.new(:dsLabel => label, :controlGroup => 'M', :blob => file)
      opts.has_key?(:dsid) ? ds.dsid=(opts[:dsid]) : nil
      add_datastream(ds)
    end
    
    def file_objects
      collection_members
    end
    
    def file_objects_append(obj)
      collection_members_append(obj)
    end
    
    def collection_members_append(obj)
      add_relationship(:has_collection_member, obj)
    end

    def collection_members_remove()
      # will rely on SemanticNode.remove_relationship once it is implemented
    end


    # 
    # Relationships Management
    #
    
    # @returns Hash of relationships, as defined by SemanticNode
    # Rely on rels_ext datastream to track relationships array
    # Overrides accessor for relationships array used by SemanticNode.
    def relationships
      return rels_ext.relationships
    end

    # Add a Rels-Ext relationship to the Object.
    # @param predicate
    # @param object Either a string URI or an object that responds to .pid 
    def add_relationship(predicate, obj)
      #predicate = ActiveFedora::RelsExtDatastream.predicate_lookup(predicate)
      r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>obj)
      rels_ext.add_relationship(r)
      rels_ext.dirty = true
    end


    def inner_object # :nodoc
      @inner_object
    end

    #return the pid of the Fedora Object
    def pid
      @inner_object.pid
    end
    
    #For Rails compatibility with url generators.
    def to_param
      self.pid
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
      @inner_object.owner_id
    end
    
    def owner_id=(owner_id)
      @inner_object.owner_id=(owner_id)
    end

    #return the create_date of the inner object (unless it's a new object)
    def create_date
      @inner_object.create_date unless new_object?
    end

    #return the modification date of the inner object (unless it's a new object)
    def modified_date
      @inner_object.modified_date unless new_object?
    end

    #return the error list of the inner object (unless it's a new object)
    def errors
      @inner_object.errors
    end
    
    #return the label of the inner object (unless it's a new object)
    def label
      @inner_object.label
    end
    
    def label=(new_label)
      @inner_object.label = new_label
    end


    def self.deserialize(doc) #:nodoc:
      pid = doc.elements['/foxml:digitalObject'].attributes['PID']
      
      proto = self.new(:pid=>pid, :new_object=>false)
      proto.datastreams.each do |name,ds|
        doc.elements.each("//foxml:datastream[@ID='#{name}']") do |el|
          # datastreams remain marked as new if the foxml doesn't have an entry for that datastream
          ds.new_object = false
          proto.datastreams[name]=ds.class.from_xml(ds, el)          
        end
      end
      proto.inner_object.new_object = false
      return proto
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
    def to_xml(xml=REXML::Document.new("<xml><fields/><content/></xml>"))
      fields_xml = xml.root.elements['fields']
      {:id => pid, :system_create_date => self.create_date, :system_modified_date => self.modified_date, :active_fedora_model => self.class.inspect}.each_pair do |attribute_name, value|
        el = REXML::Element.new(attribute_name.to_s)
        el.text = value
        fields_xml << el
      end
      datastreams.each_value do |ds|        
        ds.to_xml(fields_xml) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::RelsExtDatastream)
      end
      return xml.to_s
    end

    #Return a Solr::Document version of this object.
    def to_solr(solr_doc = Solr::Document.new)
      solr_doc << {SOLR_DOCUMENT_ID.to_sym => pid, solr_name(:system_create, :date) => self.create_date, solr_name(:system_modified, :date) => self.modified_date, solr_name(:active_fedora_model, :symbol) => self.class.inspect}
      datastreams.each_value do |ds|
        solr_doc = ds.to_solr(solr_doc) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::RelsExtDatastream)
      end
      return solr_doc
    end

    # Updates Solr index with self.
    def update_index
      SolrService.instance.conn.update(self.to_solr)
    end

    # An ActiveRecord-ism to udpate metadata values.
    #
    # Example Usage:
    #
    # m.update_attributes(:fubar=>'baz')
    #
    # This will attempt to set the values for any fields named fubar in any of 
    # the object's datastreams. This means DS1.fubar_values and DS2.fubar_values 
    # are _both_ overwritten.  
    #
    # If you want to specify which datastream(s) to update,
    # use the :datastreams argument like so:
    #  m.update_attributes({:fubar=>'baz'}, :datastreams=>"my_ds")
    # or
    #  m.update_attributes({:fubar=>'baz'}, :datastreams=>["my_ds", "my_other_ds"])
    def update_attributes(params={}, opts={})
      params.each do |k,v|
        if v == :delete || v == "" || v == nil
          v = []
        end
        if opts[:datastreams]
          ds_array = []
          opts[:datastreams].each do |dsname|
            ds_array << datastreams[dsname]
          end
        else
          ds_array = datastreams.values
        end
        ds_array.each do |d|
          if d.fields[k.to_sym]
            d.send("#{k}_values=", v)
          end
        end
      end
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
      if opts[:datastreams]
        ds_array = []
        opts[:datastreams].each do |dsname|
          ds_array << datastreams[dsname]
        end
      else
        ds_array = datastreams.values
      end
      result = params.dup
      params.each do |key,value|
        result[key] = value.dup
        ds_array.each do |dstream|
          if dstream.fields[key.to_sym]
            aname="#{key}_values"
            curval = dstream.send("#{aname}")
            cpv=value.dup#copy this, we'll need the original for the next ds
            cpv.delete_if do |y,z| 
              if curval[y.to_i] and y.to_i > -1
                curval[y.to_i]=z
                true
              else
                false
              end
            end 
            cpv.each do |y,z| 
              curval<<z #just append everything left
              if y == "-1"
                new_array_index = curval.length - 1
                result[key][new_array_index.to_s] = params[key]["-1"]
              end
            end
            curval.delete_if {|x| x == :delete || x == "" || x == nil}
            dstream.send("#{aname}=", curval) #write it back to the ds
          end
        end
        result[key].delete("-1")
      end
      return result
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
    
    private
    def configure_defined_datastreams
      if self.class.ds_specs
        self.class.ds_specs.each do |name,ar|
          if self.datastreams.has_key?(name)
            attributes = self.datastreams[name].attributes
          else
            attributes = {:label=>""}
          end
          ds = ar.first.new(:dsid=>name)
          ar.last.call(ds)
          ds.attributes = attributes.merge(ds.attributes)
          self.add_datastream(ds)
        end
      end
    end
    
    # Deals with preparing new object to be saved to Fedora, then pushes it and its datastreams into Fedora. 
    def create
      add_relationship(:has_model, ActiveFedora::ContentModel.pid_from_ruby_class(self.class))
      @metadata_is_dirty = true
      update
      #@datastreams = datastreams_in_fedora
    end
    
    # Pushes the object and all of its new or dirty datastreams into Fedora
    def update
      result = Fedora::Repository.instance.save(@inner_object)
      datastreams_in_memory.each do |k,ds|
        if ds.dirty? || ds.new_object? 
          if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.instance_of?(ActiveFedora::RelsExtDatastream)
            @metadata_is_dirty = true
          end
          result = ds.save
        end 
      end
      refresh
      return result
    end


  end
end
