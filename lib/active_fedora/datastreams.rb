module ActiveFedora
  module Datastreams
    extend ActiveSupport::Concern

    included do
      class_attribute :ds_specs
      self.ds_specs = {'RELS-EXT'=> {:type=> ActiveFedora::RelsExtDatastream, :label=>"Fedora Object-to-Object Relationship Metadata", :control_group=>'X', :block=>nil}}
      class << self
        def inherited_with_datastreams(kls) #:nodoc:
          ## Do some inheritance logic that doesn't override Base.inherited
          inherited_without_datastreams kls
          # each subclass should get a copy of the parent's datastream definitions, it should not add to the parent's definition table.
          kls.ds_specs = kls.ds_specs.dup
        end
        alias_method_chain :inherited, :datastreams
      end

      before_save :add_disseminator_location_to_datastreams
      before_save :serialize_datastreams
    end

    def serialize_datastreams
      datastreams.each {|k, ds| ds.serialize! }
      self.metadata_is_dirty = datastreams.any? do |k,ds| 
        ds.changed? && (ds.class.included_modules.include?(ActiveFedora::MetadataDatastreamHelper) || ds.instance_of?(ActiveFedora::RelsExtDatastream) || ds.kind_of?(ActiveFedora::RDFDatastream))
      end
     true
    end

    # Adds the disseminator location to the datastream after the pid has been established
    def add_disseminator_location_to_datastreams
      self.class.ds_specs.each do |name,ds_config|
        ds = datastreams[name]
        if ds && ds.controlGroup == 'E' && ds_config[:disseminator].present?
          ds.dsLocation= "#{ActiveFedora.config_for_environment[:url]}/objects/#{pid}/methods/#{ds_config[:disseminator]}"
        end
      end
      true
    end

    ## Given a method name, return the best-guess dsid
    def corresponding_datastream_name(method_name)
      dsid = method_name.to_s
      return dsid if datastreams.has_key? dsid
      unescaped_name = method_name.to_s.gsub('_', '-')
      return unescaped_name if datastreams.has_key? unescaped_name
      nil
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
      inner_object.datastream_object_for name, ds_spec
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
      ActiveSupport::Deprecation.warn "Warning: ActiveFedora::Base.add has been deprecatedand will be removed in 5.0.  Use add_datastream"
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
    #@deprecated
    def file_streams
      ActiveSupport::Deprecation.warn("ActiveFedora::Base#file_streams has been deprecated and will be removed in 5.0")
      results = []
      datastreams.each_value do |ds|
        if !ds.kind_of?(ActiveFedora::MetadataDatastream) && !ds.kind_of?(ActiveFedora::NokogiriDatastream)
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
    # @param [Hash] opts options: :dsid, :label, :mimeType, :prefix, :checksumType
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
      attrs[:checksumType] = opts[:checksumType] if opts[:checksumType]
      attrs[:versionable] = opts[:versionable] unless opts[:versionable].nil?
      ds = create_datastream(self.class.datastream_class_for_name(opts[:dsid]), opts[:dsid], attrs)
      add_datastream(ds)
    end
    
    
    def create_datastream(type, dsid, opts={})
      dsid = generate_dsid(opts[:prefix] || "DS") if dsid == nil
      klass = type.kind_of?(Class) ? type : type.constantize
      raise ArgumentError, "Argument dsid must be of type string" unless dsid.kind_of?(String) || dsid.kind_of?(NilClass)
      ds = klass.new(inner_object, dsid)
      [:mimeType, :controlGroup, :dsLabel, :dsLocation, :checksumType, :versionable].each do |key|
        ds.send("#{key}=".to_sym, opts[key]) unless opts[key].nil?
      end
      blob = opts[:blob] 
      if blob 
        if !ds.mimeType.present? 
          ##TODO, this is all done by rubydora -- remove
          ds.mimeType = blob.respond_to?(:content_type) ? blob.content_type : "application/octet-stream"
        end
        if !ds.dsLabel.present? && blob.respond_to?(:path)
          ds.dsLabel = File.basename(blob.path)
        end
      end

      ds.content = blob || "" 
      ds
    end

    # This method provides validation of proper options for control_group 'E' and 'R' and builds an attribute hash to be merged back into ds.attributes prior to saving
    #
    # @param [Object] ds The datastream
    # @param [Object] ds_config hash of options which may contain :disseminator and :url
    def additional_attributes_for_external_and_redirect_control_groups(ds,ds_config)
      if ds.controlGroup=='E'
        if !ds_config[:disseminator].present? && ds_config[:url].present?
          ds.dsLocation= ds_config[:url]
        end
      elsif ds.controlGroup=='R'
        ds.dsLocation= ds_config[:url]
      end
    end


    module ClassMethods
      #This method is used to specify the details of a datastream. 
      #args must include :name. Note that this method doesn't actually
      #execute the block, but stores it at the class level, to be executed
      #by any future instantiations.
      #
      # @param [Hash] args 
      # @option args [Class] :type The class that will represent this datastream, should extend ``Datastream''
      # @option args [String] :name the handle to refer to this datastream as
      # @option args [String] :label sets the fedora label
      # @option args [String] :control_group must be one of 'E', 'X', 'M', 'R'
      # @option args [String] :disseminator Sets the disseminator location see {#add_disseminator_location_to_datastreams}
      # @option args [String] :url 
      # @option args [Boolean] :autocreate Always create this datastream on new objects
      # @option args [Boolean] :versionable Should versioned datastreams be stored
      # @yield block executed by some kinds of datastreams
      def has_metadata(args, &block)
        spec = {:autocreate => args.fetch(:autocreate, true), :type => args[:type], :label =>  args.fetch(:label,""), :control_group => args[:control_group], :disseminator => args.fetch(:disseminator,""), :url => args.fetch(:url,""),:block => block}
        spec[:versionable] = args[:versionable] if args.has_key? :versionable
        ds_specs[args[:name]]= spec
      end

      # Specify the attributes of a file bearing datastream 
      #
      # @param [Hash] args 
      # @option args :name ("content") The dsid of the datastream
      # @option args :type (ActiveFedora::Datastream) The class the datastream should have
      # @option args :label ("File Datastream") The default value to put in the dsLabel field
      # @option args :control_group ("M") The type of controlGroup to store the datastream as. Defaults to M
      # @option args [Boolean] :autocreate Always create this datastream on new objects
      # @option args [Boolean] :versionable Should versioned datastreams be stored
      def has_file_datastream(args = {})
        spec = {:autocreate => args.fetch(:autocreate, true), :type => args.fetch(:type,ActiveFedora::Datastream),
                :label =>  args.fetch(:label,"File Datastream"), :control_group => args.fetch(:control_group,"M")}
        spec[:versionable] = args[:versionable] if args.has_key? :versionable
        ds_specs[args.fetch(:name, "content")]= spec
      end
    end

  end
end
