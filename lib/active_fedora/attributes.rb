require 'active_model/forbidden_attributes_protection'
require 'deprecation'
module ActiveFedora
  module Attributes
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = 'ActiveFedora 10.0'
    include ActiveModel::Dirty
    include ActiveModel::ForbiddenAttributesProtection

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
      sanitize_for_mass_assignment(properties).each do |k, v|
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
        # Use the generated method so that single value assetions are single
        self.send(key)
      else
        # The attribute is a delegate to a datastream
        array_reader(key)
      end
    end

    def []=(key, value)
      raise ReadOnlyRecord if readonly?
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

      def has_attributes(*fields, &block)
        options = fields.pop
        delegate_target = options.delete(:datastream)
        raise ArgumentError, "You must provide a datastream to has_attributes" if delegate_target.blank?
        Deprecation.warn(Attributes, "has_attributes is deprecated and will be removed in ActiveFedora 10.0. Instead use:\n  property #{fields.first.inspect}, delegate_to: '#{delegate_target}', ...")

        define_delegated_accessor(fields, delegate_target, options, &block)
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

      def property name, properties={}, &block
        if properties.key?(:predicate)
          define_active_triple_accessor(name, properties, &block)
        elsif properties.key?(:delegate_to)
          define_delegated_accessor([name], properties.delete(:delegate_to), properties.reverse_merge(multiple: true), &block)
        else
          raise "You must provide `:delegate_to' or `:predicate' options to property"
        end
      end

      private

      def define_active_triple_accessor(name, properties, &block)
        warn_duplicate_predicates name, properties
        properties = { multiple: true }.merge(properties)
        find_or_create_defined_attribute(name, ActiveTripleAttribute, properties)
        raise ArgumentError, "#{name} is a keyword and not an acceptable property name." if protected_property_name? name
        reflection = ActiveFedora::Attributes::PropertyBuilder.build(self, name, properties, &block)
        ActiveTriples::Reflection.add_reflection self, name, reflection

        add_attribute_indexing_config(name, &block) if block_given?
      end

      def define_delegated_accessor(fields, delegate_target, options, &block)
        define_attribute_methods fields
        fields.each do |f|
          klass = datastream_class_for_name(delegate_target)
          attribute_properties = options.merge(delegate_target: delegate_target, klass: klass)
          find_or_create_defined_attribute f, attribute_class(klass), attribute_properties

          create_attribute_reader(f, delegate_target, options)
          create_attribute_setter(f, delegate_target, options)
          add_attribute_indexing_config(f, &block) if block_given?
        end
      end

      def add_attribute_indexing_config(name, &block)
        index_config[name] ||= ActiveFedora::Indexing::Map::IndexObject.new(name, &block)
      end

      def warn_duplicate_predicates new_name, new_properties
        new_predicate = new_properties[:predicate]
        self.properties.select{|k, existing| existing.predicate == new_predicate}.each do |key, value| 
          ActiveFedora::Base.logger.warn "Same predicate (#{new_predicate}) used for properties #{key} and #{new_name}"
        end
      end

      # @param [Symbol] field the field to find or create
      # @param [Class] klass the class to use to delegate the attribute (e.g. 
      #                ActiveTripleAttribute, OmAttribute, or RdfDatastreamAttribute)
      # @param [Hash] args 
      # @option args [String] :delegate_target the path to the delegate
      # @option args [Class] :klass the class to create
      # @option args [true,false] :multiple (false) true for multi-value fields
      # @option args [Array<Symbol>] :at path to a deep node 
      # @return [DelegatedAttribute] the found or created attribute
      def find_or_create_defined_attribute(field, klass, args)
        delegated_attributes[field] ||= klass.new(field, args)
      end

      # @param [String] dsid the datastream id
      # @return [Class] the class of the datastream
      def datastream_class_for_name(dsid)
        reflection = reflect_on_association(dsid.to_sym)
        reflection ? reflection.klass : ActiveFedora::File
      end

      def create_attribute_reader(field, dsid, args)
        define_method field do |*opts|
          array_reader(field, *opts)
        end
      end

      def create_attribute_setter(field, dsid, args)
        define_method "#{field}=".to_sym do |v|
          self[field]=v
        end
      end

      def attribute_class(klass)
        if klass < ActiveFedora::RDFDatastream
          RdfDatastreamAttribute 
        else
          OmAttribute
        end
      end

    end
  end
end
