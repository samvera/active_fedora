module ActiveFedora
  module Attributes
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    
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
        respond_to?(:"#{k}=") ? send(:"#{k}=", v) : raise(UnknownAttributeError, "#{self.class} does not have an attribute `#{k}'")
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
      if md = /^(.+)_id$/.match(field)
        # a belongs_to association reader
        association = association(md[1].to_sym)
        return association.id_reader if association
      end
      raise UnknownAttributeError, "#{self.class} does not have an attribute `#{field}'" unless self.class.defined_attributes.key?(field)
      if args.present?
        instance_exec(*args, &self.class.defined_attributes[field][:reader])
      else
        instance_exec &self.class.defined_attributes[field][:reader]
      end
    end

    def array_setter(field, args)
      if md = /^(.+)_id$/.match(field)
        # a belongs_to association writer
        association = association(md[1].to_sym)
        return association.id_writer(args) if association
      end
      raise UnknownAttributeError, "#{self.class} does not have an attribute `#{field}'" unless self.class.defined_attributes.key?(field)
      instance_exec(args, &self.class.defined_attributes[field][:setter])
    end

    # @return [Boolean] true if there is an reader method and it returns a
    # value different from the new_value.
    def value_has_changed?(field, new_value)
      new_value != array_reader(field)
    end

    def mark_as_changed(field)
      self.send("#{field}_will_change!")
    end

    def datastream_for_attribute(dsid)
      datastreams[dsid] || raise(ArgumentError, "Undefined datastream id: `#{dsid}' in has_attributes")
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
        raise ArgumentError, "You must provide a datastream to has_attributes" unless datastream
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
          ds = datastream_for_attribute(dsid)
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

        self.defined_attributes[field][:multiple] = args[:multiple].nil? ? false : args[:multiple]

        define_method field do |*opts|
          val = array_reader(field, *opts)
          self.class.multiple?(field) ? val : val.first
        end
      end


      def create_attribute_setter(field, dsid, args)
        self.defined_attributes[field] ||= {}
        self.defined_attributes[field][:setter] = lambda do |v|
          ds = datastream_for_attribute(dsid)
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
  end
end
