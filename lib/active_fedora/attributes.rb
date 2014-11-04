module ActiveFedora
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::Dirty

    included do
      include Serializers
      include PrimaryKey

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

    def attribute_names
      self.class.attribute_names
    end

    def attributes
      attribute_names.each_with_object({"id" => id}) {|key, hash| hash[key] = self[key] }
    end

    # Calling inspect may trigger a bunch of datastream loads, but it's mainly for debugging, so no worries.
    def inspect
      values = ["id: #{id.inspect}"]
      values << self.class.attribute_names.map { |attr| "#{attr}: #{self[attr].inspect}" }
      "#<#{self.class} #{values.flatten.join(', ')}>"
    end

    def [](key)
      if assoc = self.association(key.to_sym)
        # This is for id attributes stored in the rdf graph.
        assoc.reader
      elsif self.class.properties.key?(key.to_s)
        # The attribute is stored in the RDF graph for this object
        resource[key]
      else
        # The attribute is a delegate to a datastream
        array_reader(key)
      end
    end

    def []=(key, value)
      if assoc = self.association(key.to_sym)
        # This is for id attributes stored in the rdf graph.
        assoc.replace(value)
      elsif self.class.properties.key?(key.to_s)
        # The attribute is stored in the RDF graph for this object
        self.send(key.to_s+"=", value)
      else
        # The attribute is a delegate to a datastream
        array_setter(key, value)
      end
    end

    # @return [Boolean] true if there is an reader method and it returns a
    # value different from the new_value.
    def value_has_changed?(field, new_value)
      new_value != array_reader(field)
    end

    def mark_as_changed(field)
      self.send("#{field}_will_change!")
    end

    def local_attributes
      self.class.local_attributes
    end


    protected

    # override activemodel so it doesn't trigger a load of all the attributes.
    # the callback methods seem to trigger this, which means just initing an object (after_init)
    # causes a load of all the datastreams.
    def attribute_method?(attr_name) #:nodoc:
      respond_to_without_attributes?(:attributes) && self.class.delegated_attributes.include?(attr_name)
    end

    private
    def array_reader(field, *args)
      raise UnknownAttributeError, "#{self.class} does not have an attribute `#{field}'" unless self.class.delegated_attributes.key?(field)

      val = self.class.delegated_attributes[field].reader(self, *args)
      self.class.multiple?(field) ? val : val.first
    end

    def array_setter(field, args)
      raise UnknownAttributeError, "#{self.class} does not have an attribute `#{field}'" unless self.class.delegated_attributes.key?(field)
      if self.class.multiple?(field)
        if args.present? && !args.respond_to?(:each)
          raise ArgumentError, "You attempted to set the attribute `#{field}' on `#{self.class}' to a scalar value. However, this attribute is declared as being multivalued."
        end
      elsif args.respond_to?(:each) # singular
        raise ArgumentError, "You attempted to set the attribute `#{field}' on `#{self.class}' to an enumerable value. However, this attribute is declared as being singular."
      end
      self.class.delegated_attributes[field].writer(self, args)
    end

    module ClassMethods
      def attribute_names
        @attribute_names ||= delegated_attributes.keys + association_attributes - system_attributes
      end

      # Attributes that are asserted about this RdfSource (not on a datastream)
      def local_attributes
        association_attributes + properties.keys - system_attributes
      end

      # Attributes that are required by ActiveFedora and Fedora
      def system_attributes
        ['has_model', 'create_date', 'modified_date']
      end

      # Attributes that represent associations to other repository objects
      def association_attributes
        outgoing_reflections.values.map { |reflection| reflection.foreign_key.to_s }
      end

      def defined_attributes
        Deprecation.warn Attributes, "defined_attributes has been renamed to delegated_attributes. defined_attributes will be removed in ActiveFedora 9"
        delegated_attributes
      end

      def delegated_attributes
        @delegated_attributes ||= {}.with_indifferent_access
        return @delegated_attributes unless superclass.respond_to?(:delegated_attributes) and value = superclass.delegated_attributes
        @delegated_attributes = value.dup if @delegated_attributes.empty?
        @delegated_attributes
      end

      def delegated_attributes= val
        @delegated_attributes = val
      end

      def has_attributes(*fields)
        options = fields.pop
        datastream = options.delete(:datastream).to_s
        raise ArgumentError, "You must provide a datastream to has_attributes" if datastream.blank?
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
        raise UnknownAttributeError, "#{self} does not have an attribute `#{field}'" unless delegated_attributes.key?(field)
        delegated_attributes[field].multiple
      end


      def property name, properties
        find_or_create_defined_attribute(name, nil, {multiple: true}.merge(properties))
        super
      end

      private

      def find_or_create_defined_attribute(field, dsid, args)
        delegated_attributes[field] ||= DelegatedAttribute.new(field, dsid, datastream_class_for_name(dsid), args)
      end

      def create_attribute_reader(field, dsid, args)
        find_or_create_defined_attribute(field, dsid, args)

        define_method field do |*opts|
          array_reader(field, *opts)
        end
      end

      def create_attribute_setter(field, dsid, args)
        find_or_create_defined_attribute(field, dsid, args)
        define_method "#{field}=".to_sym do |v|
          self[field]=v
        end
      end
    end
  end
end
