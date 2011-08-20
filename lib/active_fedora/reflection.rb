module ActiveFedora
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    module ClassMethods
      def create_reflection(macro, name, options, active_fedora)
        case macro
          when :has_many, :belongs_to
            klass = AssociationReflection
            reflection = klass.new(macro, name, options, active_fedora)
        end
        write_inheritable_hash :reflections, name => reflection
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
        reflections[association].is_a?(AssociationReflection) ? reflections[association] : nil
      end

      class MacroReflection

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
          #@klass ||= active_record.send(:compute_type, class_name)
          @klass ||= class_name
        end



        def initialize(macro, name, options, active_fedora)
          @macro, @name, @options, @active_fedora = macro, name, options, active_fedora
        end

        # Returns a new, unsaved instance of the associated class. +options+ will
        # be passed to the class's constructor.
        def build_association(*options)
          klass.new(*options)
        end

        # Returns the name of the macro.
        #
        # <tt>composed_of :balance, :class_name => 'Money'</tt> returns <tt>:balance</tt>
        # <tt>has_many :clients</tt> returns <tt>:clients</tt>
        attr_reader :name


        # Returns the hash of options used for the macro.
        #
        # <tt>composed_of :balance, :class_name => 'Money'</tt> returns <tt>{ :class_name => "Money" }</tt>
        # <tt>has_many :clients</tt> returns +{}+
        attr_reader :options


        # Returns the class for the macro.
        #
        # <tt>composed_of :balance, :class_name => 'Money'</tt> returns the Money class
        # <tt>has_many :clients</tt> returns the Client class
        def klass
          @klass ||= class_name.constantize
        end

        # Returns the class name for the macro.
        #
        # <tt>composed_of :balance, :class_name => 'Money'</tt> returns <tt>'Money'</tt>
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

        def initialize(macro, name, options, active_record)
          super
          @collection = [:has_many, :has_and_belongs_to_many].include?(macro)
        end

        def primary_key_name
          @primary_key_name ||= options[:foreign_key] || derive_primary_key_name
        end

        private

        def derive_primary_key_name
          'pid'
        end        

      end
    end
  end
end


