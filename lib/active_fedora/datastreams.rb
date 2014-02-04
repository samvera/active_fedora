module ActiveFedora
  module Datastreams
    extend ActiveSupport::Concern

    autoload :NokogiriDatastreams,           'active_fedora/datastreams/nokogiri_datastreams'

    included do
      class_attribute :ds_specs
      self.ds_specs = {'RELS-EXT'=> {:type=> ActiveFedora::RelsExtDatastream, :label=>"Fedora Object-to-Object Relationship Metadata", :block=>nil}}
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
      #before_save :serialize_datastreams
    end

    def ds_specs
      self.class.ds_specs
    end

    def serialize_datastreams
      datastreams.each {|k, ds| ds.serialize! }
    end

    # Adds the disseminator location to the datastream after the pid has been established
    def add_disseminator_location_to_datastreams
      self.ds_specs.each do |name,ds_config|
        ds = datastreams[name]
        if ds && ds.controlGroup == 'E' && ds_config[:disseminator].present?
          ds.dsLocation= "#{ActiveFedora.config_for_environment[:url]}/objects/#{pid}/methods/#{ds_config[:disseminator]}"
        end
      end
      true
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
  
    def configure_datastream(ds, ds_spec=nil)
      ds_spec ||= self.ds_specs[ds.dsid]
      if ds_spec
        ds.model = self if ds_spec[:type] == RelsExtDatastream
        # If you called has_metadata with a block, pass the block into the Datastream class
        if ds_spec[:block].class == Proc
          ds_spec[:block].call(ds)
        end
      end
    end

    def datastream_from_spec(ds_spec, name)
      inner_object.datastream_object_for name, {}, ds_spec
    end

    def load_datastreams
      local_ds_specs = self.ds_specs.dup
      inner_object.datastreams.each do |dsid, ds|
        self.add_datastream(ds)
        configure_datastream(datastreams[dsid])
        local_ds_specs.delete(dsid)
      end
      local_ds_specs.each do |name,ds_spec|
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
      datastream.dsid
    end

    # @return [Array] all datastreams that return true for `metadata?` and are not Rels-ext
    def metadata_streams
      datastreams.select { |k, ds| ds.metadata? }.reject { |k, ds| ds.kind_of?(ActiveFedora::RelsExtDatastream) }.values
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
      add_datastream(ds).tap do |dsid|
        self.class.build_datastream_accessor(dsid) unless respond_to? dsid
      end
    end
    
    
    def create_datastream(type, dsid, opts={})
      dsid ||= generate_dsid(opts[:prefix] || "DS")
      klass = type.kind_of?(Class) ? type : type.constantize
      raise ArgumentError, "Argument dsid must be of type string" unless dsid.kind_of?(String)
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

    module ClassMethods
      # @param [String] dsid the datastream id
      # @return [Class] the class of the datastream
      def datastream_class_for_name(dsid)
        ds_specs[dsid] ? ds_specs[dsid].fetch(:type, ActiveFedora::Datastream) : ActiveFedora::Datastream
      end

      # This method is used to specify the details of a datastream. 
      # You can pass the name as the first argument and a hash of options as the second argument
      # or you can pass the :name as a value in the args hash. Either way, name is required.
      # Note that this method doesn't actually execute the block, but stores it, to be executed
      # by any the implementation of the datastream(specified as :type)
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
      def has_metadata(*args, &block)
        @metadata_ds_defaults ||= {
          :autocreate => false,
          :type=>nil,
          :label=>"",
          :control_group=>nil,
          :disseminator=>"",
          :url=>"",
          :name=>nil
        }
        spec_datastream(args, @metadata_ds_defaults, &block)
      end

      
      # @overload has_file_datastream(name, args)
      #   Declares a file datastream exists for objects of this type
      #   @param [String] name 
      #   @param [Hash] args 
      #     @option args :type (ActiveFedora::Datastream) The class the datastream should have
      #     @option args :label ("File Datastream") The default value to put in the dsLabel field
      #     @option args :control_group ("M") The type of controlGroup to store the datastream as. Defaults to M
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      #     @option args [Boolean] :versionable Should versioned datastreams be stored
      # @overload has_file_datastream(args)
      #   Declares a file datastream exists for objects of this type
      #   @param [Hash] args 
      #     @option args :name ("content") The dsid of the datastream
      #     @option args :type (ActiveFedora::Datastream) The class the datastream should have
      #     @option args :label ("File Datastream") The default value to put in the dsLabel field
      #     @option args :control_group ("M") The type of controlGroup to store the datastream as. Defaults to M
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      #     @option args [Boolean] :versionable Should versioned datastreams be stored
      def has_file_datastream(*args)
        @file_ds_defaults ||= {
          :autocreate => false,
          :type=>ActiveFedora::Datastream,
          :label=>"File Datastream",
          :control_group=>"M",
          :name=>"content"
        }
        spec_datastream(args, @file_ds_defaults)
      end

      def build_datastream_accessor(dsid)
        name = name_for_dsid(dsid)
        define_method name do
          datastreams[dsid]
        end
        end


      private

      # Creates a datastream spec combining the given args and default values
      # @param args [Array] either [String, Hash] or [Hash]; the latter must .has_key? :name
      # @param defaults [Hash] the default values for the datastream spec
      # @yield block executed by some kinds of datastreams
      def spec_datastream(args, defaults, &block)
        if args.first.is_a? String 
          name = args.first
          args = args[1] || {}
          args[:name] = name
        else
          args = args.first || {}
        end
        spec = defaults.merge(args.select {|key, value| defaults.has_key? key})
        name = spec.delete(:name)
        raise ArgumentError, "You must provide a name (dsid) for the datastream" unless name
        raise ArgumentError, "You must provide a :type property for the datastream '#{name}'" unless spec[:type]
        spec[:versionable] = args[:versionable] if args.has_key? :versionable
        spec[:block] = block if block
        build_datastream_accessor(name)
        ds_specs[name]= spec
      end

        ## Given a dsid return a standard name
        def name_for_dsid(dsid)
          dsid.gsub('-', '_')
        end

    end

  end
end
