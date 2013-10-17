module ActiveFedora
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    included do
      class_attribute :reflections
      self.reflections = {}
    end

    module ClassMethods
      def reflection_name_for_predicate(predicate)
        reflections.each do |k, v|
          return k if v.options[:property] == predicate
        end
      end

      def create_reflection(macro, name, options, active_fedora)
        case macro
          when :has_many, :belongs_to, :has_and_belongs_to_many
            klass = AssociationReflection
            reflection = klass.new(macro, name, options, active_fedora)
        end

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      # Returns a hash containing all AssociationReflection objects for the current class.
      # Example:
      #
      #   Invoice.reflections
      #   Account.reflections
      #
      def reflections
        read_inheritable_attribute(:reflections) || write_inheritable_attribute(:reflections, {})
      end

      # Returns the AssociationReflection object for the +association+ (use the symbol).
      #
      #   Account.reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
      #
      def reflect_on_association(association)
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


      class MacroReflection
        # Returns the name of the macro.
        #
        # <tt>has_many :clients</tt> returns <tt>:clients</tt>
        attr_reader :name

        # Returns the macro type.
        #
        # <tt>has_many :clients</tt> returns <tt>:has_many</tt>
        attr_reader :macro

        # Returns the hash of options used for the macro.
        #
        # <tt>has_many :clients</tt> returns +{}+
        attr_reader :options

        attr_reader :active_fedora

        # Returns the target association's class.
        #
        #   class Author < ActiveRecord::Base
        #     has_many :books
        #   end
        #
        #   Author.reflect_on_association(:books).klass
        #   # => Book
        #
        # <b>Note:</b> Do not call +klass.new+ or +klass.create+ to instantiate
        # a new association object. Use +build_association+ or +create_association+
        # instead. This allows plugins to hook into association object creation.
        def klass
          @klass ||= class_name.constantize
        end

        def initialize(macro, name, options, active_fedora)
          @macro, @name, @options, @active_fedora = macro, name, options, active_fedora
          @automatic_inverse_of = nil
        end

        # Returns a new, unsaved instance of the associated class. +options+ will
        # be passed to the class's constructor.
        def build_association(*options)
          klass.new(*options)
        end


        # Returns the class name for the macro.
        #
        # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
        def class_name
          @class_name ||= options[:class_name] || derive_class_name
        end

        # Returns whether or not this association reflection is for a collection
        # association. Returns +true+ if the +macro+ is either +has_many+ or
        # +has_and_belongs_to_many+, +false+ otherwise.
        def collection?
          @collection
        end

        # Returns +true+ if +self+ is a +belongs_to+ reflection.
        def belongs_to?
          macro == :belongs_to
        end

        private
          def derive_class_name
            class_name = name.to_s.camelize
            class_name = class_name.singularize if collection?
            class_name
          end

          def derive_foreign_key
            if belongs_to?
              "#{name}_id"
            elsif options[:as]
              "#{options[:as]}_id"
            else
              active_fedora.name.foreign_key
            end
          end
      end

      # Holds all the meta-data about an association as it was specified in the
      # Active Record class.
      class AssociationReflection < MacroReflection #:nodoc:

        def initialize(macro, name, options, active_fedora)
          super
          @collection = [:has_many, :has_and_belongs_to_many].include?(macro)
        end


        # Returns a new, unsaved instance of the associated class. +options+ will
        # be passed to the class's constructor.
        def build_association(*options)
          klass.new(*options)
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

        # def primary_key_name
        #   @primary_key_name ||= options[:foreign_key] || derive_primary_key_name
        # end

        def inverse_of
          return unless inverse_name

          @inverse_of ||= klass.reflect_on_association inverse_name
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
          case macro
          when :belongs_to
            Associations::BelongsToAssociation
          when :has_and_belongs_to_many
            Associations::HasAndBelongsToManyAssociation
          when :has_many
            Associations::HasManyAssociation
          end
        end

        VALID_AUTOMATIC_INVERSE_MACROS = [:has_many, :has_and_belongs_to_many, :belongs_to]
        INVALID_AUTOMATIC_INVERSE_OPTIONS = [:conditions, :through, :polymorphic, :foreign_key]
        

        private

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
        

        # returns either nil or the inverse association name that it finds.
        def automatic_inverse_of
          if can_find_inverse_of_automatically?(self)
            inverse_name = ActiveSupport::Inflector.underscore(active_fedora.name).to_sym

            begin
              reflection = klass.reflect_on_association(inverse_name)
            rescue NameError
              # Give up: we couldn't compute the klass type so we won't be able
              # to find any associations either.
              reflection = false
            end

            if valid_inverse_reflection?(reflection)
              return inverse_name
            end
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
            #&& !reflection.scope
        end

        # def derive_primary_key_name
        #   'pid'
        # end        

      end
    end
  end
end


