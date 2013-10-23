module ActiveFedora
  module Attributes
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    extend Deprecation
    self.deprecation_horizon = 'active-fedora 7.0.0'
    
    
    autoload :Serializers

    included do
      include Serializers
      after_save :clear_changed_attributes
      def clear_changed_attributes
        @previously_changed = changes
        @changed_attributes.clear
      end
    end

    def attributes=(properties)
      properties.each do |k, v|
        respond_to?(:"#{k}=") ? send(:"#{k}=", v) : raise(UnknownAttributeError, "unknown attribute: #{k}")
      end
    end

    # Calling inspect may trigger a bunch of loads, but it's mainly for debugging, so no worries.
    def inspect
      values = self.class.defined_attributes.keys.map {|r| "#{r}:#{send(r).inspect}"}
      "#<#{self.class} pid:\"#{pretty_pid}\", #{values.join(', ')}>"
    end

    def [](key)
      array_reader(key)
    end

    def []=(key, value)
      array_setter(key, value)
    end


    private
    def array_reader(field, *args)
      raise UnknownAttributeError, "#{self.class} does not have an attribute `#{field}'" unless self.class.defined_attributes.key?(field)
      if args.present?
        instance_exec(*args, &self.class.defined_attributes[field][:reader])
      else
        instance_exec &self.class.defined_attributes[field][:reader]
      end
    end

    def array_setter(field, args)
      raise UnknownAttributeError, "#{self.class} does not have an attribute `#{field}'" unless self.class.defined_attributes.key?(field)
      instance_exec(args, &self.class.defined_attributes[field][:setter])
    end

    # @return [Boolean] true if there is an reader method and it returns a
    # value different from the new_value.
    def value_has_changed?(field, new_value)
      begin
        new_value != array_reader(field)
      rescue NoMethodError
        false
      end
    end

    def mark_as_changed(field)
      self.send("#{field}_will_change!")
    end



    module ClassMethods
      def defined_attributes
        @defined_attributes ||= {}.with_indifferent_access
        return @defined_attributes unless superclass.respond_to?(:defined_attributes) and value = superclass.defined_attributes
        @defined_attributes = value.dup if @defined_attributes.empty?
        @defined_attributes
      end

      def defined_attributes= val
        @defined_attributes = val
      end

      def has_attributes(*fields)
        options = fields.pop
        datastream = options.delete(:datastream)
        define_attribute_methods fields
        fields.each do |f|
          create_attribute_reader(f, datastream, options)
          create_attribute_setter(f, datastream, options)
        end
      end

      # Reveal if the attribute has been declared unique
      # @param [Symbol] field the field to query
      # @return [Boolean]
      def unique?(field)
        !multiple?(field)
      end

      # Reveal if the attribute is multivalued
      # @param [Symbol] field the field to query
      # @return [Boolean]
      def multiple?(field)
        defined_attributes[field][:multiple]
      end



      private
      def create_attribute_reader(field, dsid, args)
        self.defined_attributes[field] ||= {}
        self.defined_attributes[field][:reader] = lambda do |*opts|
          ds = self.send(dsid)
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send(field)
          else
            terminology = args[:at] || [field]
            if terminology.length == 1 && opts.present?
              ds.send(terminology.first, *opts)
            else
              ds.send(:term_values, *terminology)
            end
          end
        end

        if !args[:multiple].nil?
          self.defined_attributes[field][:multiple] = args[:multiple]
        elsif !args[:unique].nil?
          i = 0 
          begin 
            match = /in `(delegate.*)'/.match(caller[i])
            i+=1
          end while match.nil?

          prev_method = match.captures.first
          Deprecation.warn Attributes, "The :unique option for `#{prev_method}' is deprecated. Use :multiple instead. :unique will be removed in ActiveFedora 7", caller(i+1)
          self.defined_attributes[field][:multiple] = !args[:unique]
        else 
          i = 0 
          begin 
            match = /in `(delegate.*)'/.match(caller[i])
            i+=1
          end while match.nil?

          prev_method = match.captures.first
          Deprecation.warn Attributes, "You have not explicitly set the :multiple option on `#{prev_method}'. The default value will switch from true to false in ActiveFedora 7, so if you want to future-proof this application set `multiple: true'", caller(i+ 1)
          self.defined_attributes[field][:multiple] = true # this should be false for ActiveFedora 7
        end

        define_method field do |*opts|
          val = array_reader(field, *opts)
          self.class.multiple?(field) ? val : val.first
        end
      end


      def create_attribute_setter(field, dsid, args)
        self.defined_attributes[field] ||= {}
        self.defined_attributes[field][:setter] = lambda do |v|
          ds = self.send(dsid)
          mark_as_changed(field) if value_has_changed?(field, v)
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send("#{field}=", v)
          else
            terminology = args[:at] || [field]
            ds.send(:update_indexed_attributes, {terminology => v})
          end
        end
        define_method "#{field}=".to_sym do |v|
          self[field]=v
        end
      end

    end
    

    public

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
      Deprecation.warn(Attributes, 'update_indexed_attributes is deprecated and will be removed in ActiveFedora 7.0.0. Consider using dsid.update_indexed_attributes() instead.', caller)
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
      Deprecation.warn(Attributes, 'update_datastream_attributes is deprecated and will be removed in ActiveFedora 7.0.0. Consider using delegate_to instead.', caller)
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
      Deprecation.warn(Attributes, 'get_values_from_datastream is deprecated and will be removed in ActiveFedora 7.0.0. Consider using Datastream#get_values instead.', caller)
      if datastreams.include?(dsid)
        return datastreams[dsid].get_values(field_key,default)
      else
        return nil
      end
    end
  end
end
