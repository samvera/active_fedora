module ActiveFedora
  module Datastreams
    extend ActiveSupport::Concern

    autoload :NokogiriDatastreams, 'active_fedora/datastreams/nokogiri_datastreams'

    included do
      class_attribute :ds_specs
      self.ds_specs = {}
      class << self
        def inherited_with_datastreams(kls) #:nodoc:
          ## Do some inheritance logic that doesn't override Base.inherited
          inherited_without_datastreams kls
          # each subclass should get a copy of the parent's datastream definitions, it should not add to the parent's definition table.
          kls.ds_specs = kls.ds_specs.dup
        end
        alias_method_chain :inherited, :datastreams
      end

      #before_save :serialize_datastreams
    end

    def ds_specs
      self.class.ds_specs
    end

    def serialize_datastreams
      datastreams.each {|k, ds| ds.serialize! }
    end

    #
    # Datastream Management
    #
    
    # Returns all known datastreams for the object.  If the object has been 
    # saved to fedora, the persisted datastreams will be included.
    # Datastreams that have been modified in memory are given preference over 
    # the copy in Fedora.
    def datastreams
      @datastreams ||= DatastreamHash.new
    end

    def clear_datastreams
      @datastreams = nil
    end
  
    def configure_datastream(ds, ds_spec=nil)
      ds_spec ||= self.ds_specs[ds.dsid]
      if ds_spec
        # If you called has_metadata with a block, pass the block into the Datastream class
        if ds_spec[:block].class == Proc
          ds_spec[:block].call(ds)
        end
      end
    end

    include ActiveFedora::DatastreamBootstrap
    def datastream_from_spec(ds_spec, name)
      datastream_object_for name, {}, ds_spec
    end

    def load_datastreams
      local_ds_specs = self.ds_specs.dup
      # TODO load remote datastreams
      # datastreams.each do |dsid, ds|
      #   self.add_datastream(ds)
      #   configure_datastream(datastreams[dsid])
      #   local_ds_specs.delete(dsid)
      # end
      local_ds_specs.each do |name,ds_spec|
        ds = datastream_from_spec(ds_spec, name)
        self.add_datastream(ds)
        configure_datastream(ds, ds_spec)
      end
    end      

    # Adds datastream to the object.
    # @return [String] dsid of the added datastream
    def add_datastream(datastream, opts={})
      datastreams[datastream.dsid] = datastream
      datastream.dsid
    end

    # @return [Array] all datastreams that return true for `metadata?` and are not Rels-ext
    def metadata_streams
      datastreams.select { |k, ds| ds.metadata? }.values
    end
    
    #
    # File Management
    #
    
    # Add the given file as a datastream in the object
    #
    # @param [File] file the file to add
    # @param [Hash] opts options: :dsid, :prefix, :checksumType
    def add_file_datastream(file, opts={})
      attrs = {:blob => file, :prefix=>opts[:prefix]}
      ds = create_datastream(self.class.datastream_class_for_name(opts[:dsid]), opts[:dsid], attrs)
      add_datastream(ds).tap do |dsid|
        self.class.build_datastream_accessor(dsid) unless respond_to? dsid
      end
    end
    
    
    def create_datastream(type, dsid, opts={})
      klass = type.kind_of?(Class) ? type : type.constantize
      raise ArgumentError, "Argument dsid must be of type string" if dsid && !dsid.kind_of?(String)
      ds = klass.new(self, dsid, prefix: opts[:prefix])
      ds.content = opts[:blob] || "" 
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
      # @option args [String] :url 
      # @option args [Boolean] :autocreate Always create this datastream on new objects
      # @option args [Boolean] :versionable Should versioned datastreams be stored
      # @yield block executed by some kinds of datastreams
      def has_metadata(*args, &block)
        @metadata_ds_defaults ||= {
          :autocreate => false,
          :type=>nil,
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
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      #     @option args [Boolean] :versionable Should versioned datastreams be stored
      # @overload has_file_datastream(args)
      #   Declares a file datastream exists for objects of this type
      #   @param [Hash] args 
      #     @option args :name ("content") The dsid of the datastream
      #     @option args :type (ActiveFedora::Datastream) The class the datastream should have
      #     @option args [Boolean] :autocreate Always create this datastream on new objects
      #     @option args [Boolean] :versionable Should versioned datastreams be stored
      def has_file_datastream(*args)
        @file_ds_defaults ||= {
          :autocreate => false,
          :type=>ActiveFedora::Datastream,
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
