require 'active_support/core_ext/module/aliasing'
module ActiveFedora
  module DatastreamCollections
    extend ActiveSupport::Concern

    included do
      class_attribute :class_named_datastreams_desc
      self.class_named_datastreams_desc = {}
      class << self
        def inherited_with_datastream_collections(kls) #:nodoc:
          ## Do some inheritance logic that doesn't override Base.inherited
          inherited_without_datastream_collections kls
          kls.class_named_datastreams_desc = kls.class_named_datastreams_desc.dup
        end
        alias_method_chain :inherited, :datastream_collections
      end
    end

    module ClassMethods

      # Allows for a datastream to be treated like any other attribute of a model class 
      # while enforcing mimeType and/or datastream type (ie. external, managed, etc.) if defined. 
      # ====Examples 
      #                 
      #  has_datastream :name=>"thumbnails",:prefix => "THUMB",:type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'                     
      #  has_datastream :name=>"EADs", :type=>ActiveFedora::Datastream, :mimeType=>"application/xml", :controlGroup=>'M' 
      #  has_datastream :name=>"external_images", :type=>ActiveFedora::Datastream, :controlGroup=>'E' 
      #
      # Required Keys in args
      #  :name  -  name to give this datastream (must be unique)
      #
      # Optional Keys in args
      #  :prefix - used to create the DSID plus an index ie. THUMB1, THUMB2.  If :prefix is not specified, defaults to :name value in all uppercase 
      #  :type - defaults to ActiveFedora::Datastream if you would like content specific class to be used supply it here
      #  :mimeType - if supplied it will ensure any datastreams added are of this type, if not supplied any mimeType is acceptabl e
      #  :controlGroup -  possible values "X", "M", "R", or "E" (InlineXML, Managed Content, Redirect, or External Referenced) If controlGroup is 'E' or 'R' it expects a dsLocation be defined when adding the datastream.
      #
      # You use the datastream attribute using helper methods created for each datastream name:
      #
      # ====Helper Method Examples
      #  thumbnails_append -  Append a thumbnail datastream
      #  thumbnails        -  Get array of thumbnail datastreams
      #  thumbnails_ids    -  Get array of dsid's for thumbnail datastreams
      #
      # When loading the list of datastreams for a name from Fedora it uses the DSID prefix to find them in Fedora
      def has_datastream(args)
        unless args.has_key?(:name)
          return false
        end
        unless args.has_key?(:prefix)
          args.merge!({:prefix=>args[:name].to_s.upcase})
        end
        unless class_named_datastreams_desc.has_key?(args[:name]) 
          class_named_datastreams_desc[args[:name]] = {} 
        end
            
        args.merge!({:mimeType=>args[:mime_type]}) if args.has_key?(:mime_type)
        
        unless class_named_datastreams_desc[args[:name]].has_key?(:type) 
          #default to type ActiveFedora::Datastream
          args.merge!({:type => "ActiveFedora::Datastream"})
        end
        class_named_datastreams_desc[args[:name]]= args   
        create_named_datastream_finders(args[:name],args[:prefix])
        create_named_datastream_update_methods(args[:name])
      end
      
      # Creates the following helper methods for a datastream name
      #   [datastream_name]_append  - Add a named datastream
      #
      # ==== Examples for "thumbnails" datastream
      #  thumbnails_append -  Append a thumbnail datastream
      # TODO: Add [datastream_name]_remove
      def create_named_datastream_update_methods(name)
        append_file_method_name = "#{name.to_s.downcase}_file_append"
        append_method_name = "#{name.to_s.downcase}_append"
        #remove_method_name = "#{name.to_s.downcase}_remove"
        self.send(:define_method,:"#{append_file_method_name}") do |*args| 
          file,opts = *args
          opts ||= {}
          add_named_file_datastream(name,file,opts)
        end
        
        self.send(:define_method,:"#{append_method_name}") do |*args| 
          #call add_named_datastream instead of add_file_named_datastream in case not managed datastream
          add_named_datastream(name,*args)
        end
      end 
      
      # Creates the following helper methods for a datastream name
      #   [datastream_name]  - Returns array of named datastreams
      #   [datastream_name]_ids - Returns array of named datastream dsids
      #
      # ==== Examples for "thumbnails" datastream
      #  thumbnails        -  Get array of thumbnail datastreams
      #  thumbnails_ids    -  Get array of dsid's for thumbnail datastreams
      def create_named_datastream_finders(name, prefix)
        class_eval <<-END,  __FILE__, __LINE__
        def #{name}(opts={})
          id_array = []
          keys = datastreams.keys

          id_array = keys.select {|v| v =~ /^#{prefix}\\d+$/}

          if opts[:response_format] == :id_array
            return id_array
          else
            named_ds = []
            id_array.each do |name|
              if datastreams.has_key?(name)
                named_ds.push(datastreams[name])
              end
            end
            return named_ds
          end
        end
        def #{name}_ids
          #{name}(:response_format => :id_array)
        end
        END
      end
      


    end

      # Accessor for class variable for hash that stores arguments passed to has_datastream calls within an
      # ActiveFedora::Base child class.    
      #  
      #  has_datastream :name=>"audio_file", :prefix=>"AUDIO", :type=>ActiveFedora::Datastream, :mimeType=>"audio/x-wav" 
      #  has_datastream :name=>"external_images", :prefix=>"EXTIMG", :type=>ActiveFedora::Datastream,:mimeType=>"image/jpeg", :controlGroup=>'E'
      #
      # The above examples result in the following hash
      #  {"audio_file"=>{:prefix=>"AUDIO",:type=>ActiveFedora::Datastream, :mimeType=>"audio/x-wav", :controlGroup=>'M'},
      #   "external_images=>{:prefix=>"EXTIMG", :type=>ActiveFedora::Datastream,:mimeType=>"image/jpeg", :controlGroup=>'E'}}
      #
      # This hash is later used when adding a named datastream such as an "audio_file" as defined above.
      def named_datastreams_desc
        self.class_named_datastreams_desc ||= {}
      end

      # Returns array of datastream names defined for this object 
      def datastream_names
        named_datastreams_desc.keys
      end
      
      # Calls add_named_datastream while assuming it will be managed content and sets :blob and :controlGroup values accordingly
      # ====Parameters
      #  name: Datastream name
      #  file: The file to add for this datastream
      #  opts: Options hash.  See +add_named_datastream+ for expected keys and values
      def add_named_file_datastream(name, file, opts={})
        opts.merge!({:blob=>file,:controlGroup=>'M'})
        add_named_datastream(name,opts)
      end
      
      # This object is used by [datastream_name]_append helper to add a named datastream
      # but can also be called directly.
      # ====Parameters
      #  name: name of datastream to add
      #  opts: hash defining datastream attributes
      # The following are expected keys in opts hash:
      #   :label => Defaults to the file name
      #   :blob or :file  => Required to point to the datastream file being added if managed content
      #   :controlGroup => defaults to 'M' for managed, can also be 'E' external and 'R' for redirected
      #   :content_type => required if the file does not respond to 'content_type' and should match :mimeType in has_datastream definition if defined
      #   :dsLocation => holds uri location of datastream.  Required only if :controlGroup is type 'E' or 'R'.
      #   :dsid or :dsId => Optional, and used to update an existing datastream with dsid supplied.  Will throw an error if dsid does not exist and does not match prefix pattern for datastream name
      def add_named_datastream(name,opts={})
        unless named_datastreams_desc.has_key?(name) && named_datastreams_desc[name].has_key?(:type) 
          raise "Failed to add datastream. Named datastream #{name} not defined for object #{pid}." 
        end

        if opts.has_key?(:mime_type)
          opts.merge!({:content_type=>opts[:mime_type]})
        elsif opts.has_key?(:mimeType)
          opts.merge!({:content_type=>opts[:mimeType]})
        end
        opts.merge!(named_datastreams_desc[name])
          
        label = opts.has_key?(:label) ? opts[:label] : ""

        #only do these steps for managed datastreams
        unless (opts.has_key?(:controlGroup)&&opts[:controlGroup]!="M")
          if opts.has_key?(:file)
            opts.merge!({:blob => opts[:file]}) 
            opts.delete(:file)
          end
          
          raise "You must define parameter blob for this managed datastream to load for #{pid}" unless opts.has_key?(:blob)
          
          #if no explicit label and is a file use original file name for label
          if !opts.has_key?(:label)&&opts[:blob].respond_to?(:original_filename)
            label = opts[:blob].original_filename
          end
          
          if opts[:blob].respond_to?(:content_type)&&!opts[:blob].content_type.nil? && !opts.has_key?(:content_type)
            opts.merge!({:content_type=>opts[:blob].content_type})
          end

          raise "The blob must respond to content_type or the hash must have :content_type or :mime_type property set" unless opts.has_key?(:content_type)
          
          #throw error for mimeType mismatch
          if named_datastreams_desc[name].has_key?(:mimeType) && !named_datastreams_desc[name][:mimeType].eql?(opts[:content_type])
            raise "Content type mismatch for add datastream #{name} to #{pid}.  Expected: #{named_datastreams_desc[name][:mimeType]}, Actual: #{opts[:content_type]}"
          end
        else 
          label = opts[:dsLocation] if (opts.has_key?(:dsLocation)) 
        end
        
        opts.merge!(:dsLabel => label)
        
        ds = create_datastream(named_datastreams_desc[name][:type], opts[:dsid], opts)
        #Must be of type datastream
        assert_kind_of 'datastream',  ds, ActiveFedora::Datastream
        #make sure dsid is nil so that it uses the prefix for mapping purposes
        #check dsid works for the prefix if it is set
        if ds.dsid && opts.has_key?(:prefix)
          raise "dsid supplied (#{ds.dsid}) does not conform to pattern #{opts[:prefix]}[number]" unless ds.dsid =~ /#{opts[:prefix]}[0-9]/
        end
        
        add_datastream(ds,opts)
      end

      # Update an existing named datastream.  It has same parameters as add_named_datastream
      # except the :dsid key is now required.
      #
      # ====TODO
      # Currently requires you to update file if a managed datastream 
      # but could change to allow metadata only updates as well
      def update_named_datastream(name, opts={})
        #check that dsid provided matches existing datastream with that name
        raise "You must define parameter dsid for datastream to update for #{pid}" unless opts.include?(:dsid)
        raise "Datastream with name #{name} and dsid #{opts[:dsid]} does not exist for #{pid}" unless self.send("#{name}_ids").include?(opts[:dsid])
        add_named_datastream(name,opts)
      end
      
      # Throws an assertion failure unless the object 'o' is kind_of? class 't'
      # ====Parameters
      #  n: Name of object
      #  o: The object to test
      #  t: The class type to check is kind_of?
      def assert_kind_of(n,o,t)
        raise "Assertion failure: #{n}: #{o} is not of type #{t}" unless o.kind_of?(t)
      end
      
      # Returns true if the name is a defined named datastream
      def is_named_datastream?(name)
        named_datastreams_desc.has_key?(name)
      end

      # Returns hash of datastream names defined by has_datastream calls mapped to 
      # array of datastream objects that have been added
      # ====Example
      # For the following has_datastream entries and a datastream defined for minivan only would be
      #  has_datastream :name=>"minivan", :prefix => "VAN", :type=>ActiveFedora::Datastream,:mimeType=>"image/jpeg", :controlGroup=>'M'
      #  has_datastream :name=>"external_images", :prefix=>"EXTIMG", :type=>ActiveFedora::Datastream,:mimeType=>"image/jpeg", :controlGroup=>'E'
      #
      # Returns
      #  {"external_images"=>[],"thumbnails"=>{#<ActiveFedora::Datastream:0x7ffd6512daf8 ...}} 
      def named_datastreams
        ds_values = {}
        self.class.class_named_datastreams_desc.keys.each do |name|
          ds_values.merge!({name=>self.send("#{name}")})
        end
        return ds_values
      end
      
      # Returns hash of datastream names mapped to an array
      # of dsid's for named datastream objects
      # === Example
      # For the following has_datastream call, assume we have added two datastreams.
      # 
      #  has_datastream :name=>"thumbnails",:prefix => "THUMB",:type=>ActiveFedora::Datastream, :mimeType=>"image/jpeg", :controlGroup=>'M'                     
      #
      # It would then return
      #  {"thumbnails=>["THUMB1", "THUMB2"]}
      def named_datastreams_ids
        dsids = {}
        self.class.class_named_datastreams_desc.keys.each do |name|
          dsid_array = self.send("#{name}_ids")
          dsids[name] = dsid_array
        end
        return dsids
      end 
      
      # Returns the hash that stores arguments passed to has_datastream calls within an
      # ActiveFedora::Base child class.    
      #  
      #  has_datastream :name=>"audio_file", :prefix=>"AUDIO", :type=>ActiveFedora::Datastream, :mimeType=>"audio/x-wav" 
      #  has_datastream :name=>"external_images", :prefix=>"EXTIMG", :type=>ActiveFedora::Datastream,:mimeType=>"image/jpeg", :controlGroup=>'E'
      #
      # The above examples result in the following hash
      #  {"audio_file"=>{:prefix=>"AUDIO",:type=>ActiveFedora::Datastream, :mimeType=>"audio/x-wav", :controlGroup=>'M'},
      #   "external_images=>{:prefix=>"EXTIMG", :type=>ActiveFedora::Datastream,:mimeType=>"image/jpeg", :controlGroup=>'E'}}
      #
      # This hash is later used when adding a named datastream such as an "audio_file" as defined above.
      def named_datastreams_desc
        @named_datastreams_desc ||= self.class.class_named_datastreams_desc
      end
      
  end
end
