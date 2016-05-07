module ActiveFedora
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    included do
      class_attribute :_reflections
      self._reflections = {}
    end

    def reflections
      self.class.reflections
    end

    class << self
      def create(macro, name, scope, options, active_fedora)
        klass = case macro
                when :has_many
                  HasManyReflection
                when :belongs_to
                  BelongsToReflection
                when :has_and_belongs_to_many
                  HasAndBelongsToManyReflection
                when :has_subresource
                  HasSubresourceReflection
                when :directly_contains
                  DirectlyContainsReflection
                when :directly_contains_one
                  DirectlyContainsOneReflection
                when :indirectly_contains
                  IndirectlyContainsReflection
                when :is_a_container
                  BasicContainsReflection
                when :rdf
                  RDFPropertyReflection
                when :singular_rdf
                  SingularRDFPropertyReflection
                when :filter
                  FilterReflection
                when :aggregation, :orders
                  OrdersReflection
                else
                  raise "Unsupported Macro: #{macro}"
                end
        reflection = klass.new(name, scope, options, active_fedora)
        add_reflection(active_fedora, name, reflection)
        reflection
      end

      def add_reflection(active_fedora, name, reflection)
        active_fedora.clear_reflections_cache
        # FIXME: this is where the problem with association_spec is caused (key is string now)
        active_fedora._reflections = active_fedora._reflections.merge(name => reflection)
      end
    end

    module ClassMethods
      # Returns a hash containing all AssociationReflection objects for the current class.
      # Example:
      #
      #   Invoice.reflections
      #   Account.reflections
      #
      def reflections
        @__reflections ||= begin
          ref = {}

          _reflections.each do |name, reflection|
            parent_reflection = reflection.parent_reflection

            if parent_reflection
              parent_name = parent_reflection.name
              ref[parent_name.to_s] = parent_reflection
            else
              ref[name] = reflection
            end
          end

          ref
        end
      end

      # Returns an array of AssociationReflection objects for all the
      # associations in the class. If you only want to reflect on a certain
      # association type, pass in the symbol (<tt>:has_many</tt>, <tt>:has_one</tt>,
      # <tt>:belongs_to</tt>) as the first parameter.
      #
      # Example:
      #
      #   Account.reflect_on_all_associations             # returns an array of all associations
      #   Account.reflect_on_all_associations(:has_many)  # returns an array of all has_many associations
      #
      def reflect_on_all_associations(macro = nil)
        association_reflections = reflections.dup
        association_reflections.select! { |_k, reflection| reflection.macro == macro } if macro
        association_reflections
      end

      # Returns the AssociationReflection object for the +association+ (use the symbol).
      #
      #   Account.reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
      #
      def reflect_on_association(association)
        _reflect_on_association(association)
      end

      def outgoing_reflections
        reflections.select { |_, reflection| reflection.is_a? RDFPropertyReflection }
      end

      def child_resource_reflections
        reflect_on_all_associations(:has_subresource).select { |_, reflection| reflection.klass <= ActiveFedora::File }
      end

      def contained_rdf_source_reflections
        reflect_on_all_associations(:has_subresource).select { |_, reflection| !(reflection.klass <= ActiveFedora::File) }
      end

      # Returns the AssociationReflection object for the +association+ (use the symbol).
      #
      #   Account._reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice._reflect_on_association(:line_items).macro  # returns :has_many
      #
      def _reflect_on_association(association)
        val = reflections[association].is_a?(AssociationReflection) ? reflections[association] : nil
        unless val
          # When a has_many is paired with a has_and_belongs_to_many the assocation will have a plural name
          association = association.to_s.pluralize.to_sym
          val = reflections[association].is_a?(AssociationReflection) ? reflections[association] : nil
        end
        val
      end

      def reflect_on_all_autosave_associations
        reflections.values.select { |reflection| reflection.options[:autosave] }
      end

      def clear_reflections_cache # :nodoc:
        @__reflections = nil
      end
    end

    # Holds all the methods that are shared between MacroReflection and ThroughReflection.
    #
    #   AbstractReflection
    #     MacroReflection
    #       AggregateReflection
    #       AssociationReflection
    #         HasManyReflection
    #         HasOneReflection
    #         BelongsToReflection
    #         HasAndBelongsToManyReflection
    #     ThroughReflection
    #       PolymorphicReflection
    #         RuntimeReflection
    class AbstractReflection # :nodoc:
      def through_reflection?
        false
      end

      # Returns a new, unsaved instance of the associated class. +attributes+ will
      # be passed to the class's constructor.
      def build_association(attributes, &block)
        klass.new(attributes, &block)
      end

      # Returns the class name for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>'Money'</tt>
      # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
      def class_name
        @class_name ||= (options[:class_name] || derive_class_name).to_s
      end

      def constraints
        scope_chain.flatten
      end

      def inverse_of
        return unless inverse_name

        @inverse_of ||= klass._reflect_on_association inverse_name
      end

      def check_validity_of_inverse!
        unless polymorphic?
          if has_inverse? && inverse_of.nil?
            raise InverseOfAssociationNotFoundError, self
          end
        end
      end

      def alias_candidate(name)
        "#{plural_name}_#{name}"
      end

      def chain
        collect_join_chain
      end
    end

    class MacroReflection < AbstractReflection
      # Returns the name of the macro.
      #
      # <tt>has_many :clients</tt> returns <tt>:clients</tt>
      attr_reader :name

      attr_reader :scope

      # Returns the hash of options used for the macro.
      #
      # <tt>has_many :clients</tt> returns +{}+
      attr_reader :options

      attr_reader :active_fedora

      def initialize(name, scope, options, active_fedora)
        @name = name
        @scope = scope
        @options = options
        @active_fedora = active_fedora
        @klass         = options[:anonymous_class]
        @automatic_inverse_of = nil
      end

      def autosave=(autosave)
        @options[:autosave] = autosave
        parent_reflection = self.parent_reflection
        parent_reflection.autosave = autosave if parent_reflection
      end

      # Returns the class for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns the Money class
      # <tt>has_many :clients</tt> returns the Client class
      def klass
        @klass ||= compute_class(class_name)
      end

      def compute_class(name)
        name.constantize
      end

      # Returns +true+ if +self+ and +other_aggregation+ have the same +name+ attribute, +active_record+ attribute,
      # and +other_aggregation+ has an options hash assigned to it.
      def ==(other)
        super ||
          other.is_a?(self.class) &&
            name == other.name &&
            !other.options.nil? &&
            active_record == other.active_record
      end

      private

        def derive_class_name
          class_name = name.to_s.camelize
          class_name = class_name.singularize if collection?
          class_name
        end
    end

    # Holds all the meta-data about an association as it was specified in the
    # Active Record class.
    class AssociationReflection < MacroReflection #:nodoc:
      attr_accessor :parent_reflection # Reflection

      def initialize(name, scope, options, active_fedora)
        super
        @constructable = calculate_constructable(macro, options)
      end

      def constructable? # :nodoc:
        @constructable
      end

      # Creates a new instance of the associated class, and immediately saves it
      # with ActiveFedora::Base#save. +options+ will be passed to the class's
      # creation method. Returns the newly created object.
      def create_association(*options)
        klass.create(*options)
      end

      def foreign_key
        @foreign_key ||= options[:foreign_key] || derive_foreign_key
      end

      # Returns the RDF predicate as defined by the :predicate option
      def predicate
        options[:predicate]
      end

      def predicate_for_solr
        predicate.fragment || predicate.to_s.rpartition(/\//).last
      end

      def solr_key
        @solr_key ||= begin
          ActiveFedora.index_field_mapper.solr_name(predicate_for_solr, :symbol)
        end
      end

      def check_validity!
        check_validity_of_inverse!
      end

      def check_validity_of_inverse!
        return if options[:polymorphic] || !(has_inverse? && inverse_of.nil?)
        raise InverseOfAssociationNotFoundError, self
      end

      # A chain of reflections from this one back to the owner. For more see the explanation in
      # ThroughReflection.
      def collect_join_chain
        [self]
      end
      alias chain collect_join_chain # todo

      def has_inverse?
        inverse_name
      end

      def inverse_of
        return unless inverse_name

        @inverse_of ||= klass._reflect_on_association inverse_name
      end

      # Returns the macro type.
      #
      # <tt>has_many :clients</tt> returns <tt>:has_many</tt>
      def macro
        raise NotImplementedError
      end

      # Returns whether or not this association reflection is for a collection
      # association. Returns +true+ if the +macro+ is either +has_many+ or
      # +has_and_belongs_to_many+, +false+ otherwise.
      def collection?
        false
      end

      # Returns whether or not the association should be validated as part of
      # the parent's validation.
      #
      # Unless you explicitly disable validation with
      # <tt>:validate => false</tt>, validation will take place when:
      #
      # * you explicitly enable validation; <tt>:validate => true</tt>
      # * you use autosave; <tt>:autosave => true</tt>
      # * the association is a +has_many+ association
      def validate?
        !options[:validate].nil? ? options[:validate] : (options[:autosave] == true || macro == :has_many)
      end

      def association_class
        raise NotImplementedError
      end

      VALID_AUTOMATIC_INVERSE_MACROS = [:has_many, :has_and_belongs_to_many, :belongs_to].freeze
      INVALID_AUTOMATIC_INVERSE_OPTIONS = [:conditions, :through, :polymorphic, :foreign_key].freeze

      # Returns +true+ if +self+ is a +belongs_to+ reflection.
      def belongs_to?
        false
      end

      def has_many?
        false
      end

      def has_and_belongs_to_many?
        false
      end

      private

        def calculate_constructable(_macro, _options)
          true
        end

        def inverse_name
          options.fetch(:inverse_of) do
            if @automatic_inverse_of == false
              nil
            else
              @automatic_inverse_of ||= automatic_inverse_of
            end
          end
        end

        # Checks if the inverse reflection that is returned from the
        # +automatic_inverse_of+ method is a valid reflection. We must
        # make sure that the reflection's active_record name matches up
        # with the current reflection's klass name.
        #
        # Note: klass will always be valid because when there's a NameError
        # from calling +klass+, +reflection+ will already be set to false.
        def valid_inverse_reflection?(reflection)
          reflection &&
            klass.name == reflection.active_fedora.name &&
            can_find_inverse_of_automatically?(reflection)
        end

        # returns either false or the inverse association name that it finds.
        def automatic_inverse_of
          if can_find_inverse_of_automatically?(self)
            inverse_name = ActiveSupport::Inflector.underscore(options[:as] || active_fedora.name.demodulize).to_sym

            begin
              reflection = klass._reflect_on_association(inverse_name)
            rescue NameError
              # Give up: we couldn't compute the klass type so we won't be able
              # to find any associations either.
              reflection = false
            end

            return inverse_name if valid_inverse_reflection?(reflection)
          end

          false
        end

        # Checks to see if the reflection doesn't have any options that prevent
        # us from being able to guess the inverse automatically. First, the
        # <tt>inverse_of</tt> option cannot be set to false. Second, we must
        # have <tt>has_many</tt>, <tt>has_one</tt>, <tt>belongs_to</tt> associations.
        # Third, we must not have options such as <tt>:polymorphic</tt> or
        # <tt>:foreign_key</tt> which prevent us from correctly guessing the
        # inverse association.
        #
        # Anything with a scope can additionally ruin our attempt at finding an
        # inverse, so we exclude reflections with scopes.
        def can_find_inverse_of_automatically?(reflection)
          reflection.options[:inverse_of] != false &&
            VALID_AUTOMATIC_INVERSE_MACROS.include?(reflection.macro) &&
            !INVALID_AUTOMATIC_INVERSE_OPTIONS.any? { |opt| reflection.options[opt] }
          # && !reflection.scope
        end

        def derive_foreign_key
          if belongs_to?
            "#{name}_id"
          elsif has_and_belongs_to_many?
            "#{name.to_s.singularize}_ids"
          elsif options[:as]
            "#{options[:as]}_id"
          elsif inverse_of && inverse_of.collection?
            # for a has_many that is the inverse of a has_and_belongs_to_many
            "#{options[:inverse_of].to_s.singularize}_ids"
          else
            # for a has_many that is the inverse of a belongs_to
            active_fedora.name.foreign_key
          end
        end
    end

    class HasManyReflection < AssociationReflection # :nodoc:
      def macro
        :has_many
      end

      def collection?
        true
      end

      def has_many?
        true
      end

      def association_class
        Associations::HasManyAssociation
      end
    end

    class BelongsToReflection < AssociationReflection # :nodoc:
      def macro
        :belongs_to
      end

      def belongs_to?
        true
      end

      def association_class
        Associations::BelongsToAssociation
      end
    end

    class HasAndBelongsToManyReflection < AssociationReflection # :nodoc:
      def macro
        :has_and_belongs_to_many
      end

      def collection?
        true
      end

      def has_and_belongs_to_many?
        true
      end

      def association_class
        Associations::HasAndBelongsToManyAssociation
      end
    end

    class HasSubresourceReflection < AssociationReflection # :nodoc:
      def macro
        :has_subresource
      end

      def association_class
        Associations::HasSubresourceAssociation
      end
    end

    class BasicContainsReflection < AssociationReflection # :nodoc:
      def macro
        :is_a_container
      end

      def collection?
        true
      end

      def association_class
        Associations::BasicContainsAssociation
      end
    end

    class DirectlyContainsReflection < AssociationReflection # :nodoc:
      def macro
        :directly_contains
      end

      def collection?
        true
      end

      def association_class
        Associations::DirectlyContainsAssociation
      end
    end

    class DirectlyContainsOneReflection < AssociationReflection # :nodoc:
      def macro
        :directly_contains_one
      end

      def association_class
        Associations::DirectlyContainsOneAssociation
      end
    end

    class IndirectlyContainsReflection < AssociationReflection # :nodoc:
      def macro
        :indirectly_contains
      end

      def collection?
        true
      end

      def association_class
        Associations::IndirectlyContainsAssociation
      end
    end

    class RDFPropertyReflection < AssociationReflection
      def initialize(*args)
        super
        active_fedora.index_config[name] = build_index_config
      end

      def macro
        :rdf
      end

      def association_class
        Associations::RDF
      end

      def collection?
        true
      end

      def derive_foreign_key
        name
      end

      def derive_class_name
        class_name = name.to_s.sub(/_ids?$/, '').camelize
        class_name = class_name.singularize if collection?
        class_name
      end

      private

        def build_index_config
          ActiveFedora::Indexing::Map::IndexObject.new(predicate_for_solr) { |index| index.as :symbol }
        end
    end

    class SingularRDFPropertyReflection < RDFPropertyReflection
      def macro
        :singular_rdf
      end

      def collection?
        false
      end

      def association_class
        Associations::SingularRDF
      end
    end

    class FilterReflection < AssociationReflection
      def macro
        :filter
      end

      def association_class
        Associations::FilterAssociation
      end

      # delegates to extending_from
      delegate :klass, to: :extending_from

      def extending_from
        @extending_from ||= active_fedora._reflect_on_association(options.fetch(:extending_from))
      end

      def collection?
        true
      end
    end

    class OrdersReflection < AssociationReflection
      def macro
        :orders
      end

      def association_class
        Associations::OrdersAssociation
      end

      def collection?
        true
      end

      def class_name
        klass.to_s
      end

      def unordered_reflection
        options[:unordered_reflection]
      end

      def klass
        ActiveFedora::Orders::ListNode
      end
    end
  end
end
