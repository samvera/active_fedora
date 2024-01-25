require 'active_support/core_ext/module'

module ActiveFedora
  module Scoping
    extend ActiveSupport::Concern

    included do
      include Default
      include Named
    end

    module ClassMethods
      def current_scope # :nodoc:
        ScopeRegistry.value_for(:current_scope, self)
      end

      def current_scope=(scope) # :nodoc:
        ScopeRegistry.set_value_for(:current_scope, self, scope)
      end

      # Collects attributes from scopes that should be applied when creating
      # an AF instance for the particular class this is called on.
      def scope_attributes # :nodoc:
        all.scope_for_create
      end

      # Are there attributes associated with this scope?
      def scope_attributes? # :nodoc:
        current_scope
      end
    end

    def populate_with_current_scope_attributes # :nodoc:
      return unless self.class.scope_attributes?

      self.class.scope_attributes.each do |att, value|
        send("#{att}=", value) if respond_to?("#{att}=")
      end
    end

    def initialize_internals_callback # :nodoc:
      super
      populate_with_current_scope_attributes
    end

    # This class stores the +:current_scope+ and +:ignore_default_scope+ values
    # for different classes. The registry is stored as a thread local, which is
    # accessed through +ScopeRegistry.current+.
    #
    # This class allows you to store and get the scope values on different
    # classes and different types of scopes. For example, if you are attempting
    # to get the current_scope for the +Board+ model, then you would use the
    # following code:
    #
    #   registry = ActiveFedora::Scoping::ScopeRegistry
    #   registry.set_value_for(:current_scope, Board, some_new_scope)
    #
    # Now when you run:
    #
    #   registry.value_for(:current_scope, Board)
    #
    # You will obtain whatever was defined in +some_new_scope+. The #value_for
    # and #set_value_for methods are delegated to the current ScopeRegistry
    # object, so the above example code can also be called as:
    #
    #   ActiveFedora::Scoping::ScopeRegistry.set_value_for(:current_scope,
    #       Board, some_new_scope)
    class ScopeRegistry # :nodoc:
      VALID_SCOPE_TYPES = [:current_scope, :ignore_default_scope].freeze

      thread_mattr_accessor :_registry
      def self.registry
        self._registry ||= Hash.new { |hash, key| hash[key] = {} }
      end

      # Obtains the value for a given +scope_type+ and +model+.
      def self.value_for(scope_type, model)
        raise_invalid_scope_type!(scope_type)
        klass = model
        base = model.base_class
        while klass <= base
          value = registry[scope_type][klass.name]
          return value if value
          klass = klass.superclass
        end
      end

      # Sets the +value+ for a given +scope_type+ and +model+.
      def self.set_value_for(scope_type, model, value)
        raise_invalid_scope_type!(scope_type)
        registry[scope_type][model.name] = value
      end

      # @api private
      def self.raise_invalid_scope_type!(scope_type)
        raise ArgumentError, "Invalid scope type '#{scope_type}' sent to the registry. Scope types must be included in VALID_SCOPE_TYPES" unless VALID_SCOPE_TYPES.include?(scope_type)
      end
    end
  end
end
