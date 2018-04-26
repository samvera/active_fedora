require 'active_model/forbidden_attributes_protection'
module ActiveFedora
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::Dirty
    include ActiveModel::ForbiddenAttributesProtection

    included do
      include Serializers
      include PrimaryKey

      after_save :clear_changed_attributes
      def clear_changed_attributes
        @previously_changed = changes
        clear_attribute_changes(changes.keys)
      end
    end

    def attribute_names
      self.class.attribute_names
    end

    def attributes
      attribute_names.each_with_object("id" => id) { |key, hash| hash[key] = self[key] }
    end

    def [](key)
      if assoc = association(key.to_sym)
        # This is for id attributes stored in the rdf graph.
        assoc.reader
      elsif self.class.properties.key?(key.to_s) || self.class.attributes_with_defaults.include?(key.to_s)
        # Use the generated method so that single value assetions are single
        send(key)
      else
        raise ArgumentError, "Unknown attribute #{key}"
      end
    end

    def []=(key, value)
      raise ReadOnlyRecord if readonly?
      if assoc = association(key.to_sym)
        # This is for id attributes stored in the rdf graph.
        assoc.replace(value)
      elsif self.class.properties.key?(key.to_s)
        # The attribute is stored in the RDF graph for this object
        send(key.to_s + "=", value)
      else
        raise ArgumentError, "Unknown attribute #{key}"
      end
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

        # From ActiveFedora::FedoraAttributes
        def attributes_with_defaults
          ['type', 'rdf_label']
        end

        # Attributes that represent associations to other repository objects
        def association_attributes
          outgoing_reflections.values.map { |reflection| reflection.foreign_key.to_s }
        end

        def delegated_attributes
          @delegated_attributes ||= {}.with_indifferent_access
          return @delegated_attributes unless superclass.respond_to?(:delegated_attributes) && value = superclass.delegated_attributes
          @delegated_attributes = value.dup if @delegated_attributes.empty?
          @delegated_attributes
        end

        def delegated_attributes=(val)
          @delegated_attributes = val
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
          raise UnknownAttributeError.new(nil, field, self) unless delegated_attributes.key?(field)
          delegated_attributes[field].multiple
        end

        def property(name, properties = {}, &block)
          raise ArgumentError, "You must provide a `:predicate' option to property" unless properties.key?(:predicate)
          define_active_triple_accessor(name, properties, &block)
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

          def add_attribute_indexing_config(name, &block)
            index_config[name] ||= ActiveFedora::Indexing::Map::IndexObject.new(name, &block)
          end

          def warn_duplicate_predicates(new_name, new_properties)
            new_predicate = new_properties[:predicate]
            properties.select { |_k, existing| existing.predicate == new_predicate }.each do |key, _value|
              ActiveFedora::Base.logger.warn "Same predicate (#{new_predicate}) used for properties #{key} and #{new_name}"
            end
          end

          # @param [Symbol] field the field to find or create
          # @param [Class] klass the class to use to delegate the attribute (e.g.
          #                ActiveTripleAttribute)
          # @param [Hash] args
          # @option args [String] :delegate_target the path to the delegate
          # @option args [Class] :klass the class to create
          # @option args [true,false] :multiple (false) true for multi-value fields
          # @option args [Array<Symbol>] :at path to a deep node
          # @return [DelegatedAttribute] the found or created attribute
          def find_or_create_defined_attribute(field, klass, args)
            delegated_attributes[field] ||= klass.new(field, args)
          end
      end
  end
end
