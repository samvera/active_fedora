# frozen_string_literal: true
require 'active_fedora/associations'
module ActiveFedora::Associations::Builder
  class CollectionAssociation < Association # :nodoc:
    CALLBACKS = [:before_add, :after_add, :before_remove, :after_remove].freeze

    def self.valid_options(options)
      super + CALLBACKS
    end

    def self.define_callbacks(model, reflection)
      super
      name = reflection.name
      options = reflection.options
      CALLBACKS.each { |callback_name| define_callback(model, callback_name, name, options) }
    end

    def self.define_extensions(model, name)
      return unless block_given?

      extension_module_name = "#{model.name.demodulize}#{name.to_s.camelize}AssociationExtension"
      extension = Module.new(&Proc.new)
      model.parent.const_set(extension_module_name, extension)
    end

    def self.define_callback(model, callback_name, name, options)
      full_callback_name = "#{callback_name}_for_#{name}"

      # TODO : why do i need method_defined? I think its because of the inheritance chain
      # See https://github.com/samvera/active_fedora/issues/1333
      model.class_attribute full_callback_name.to_sym unless model.method_defined?(full_callback_name)

      callbacks = Array(options[callback_name.to_sym]).map do |callback|
        case callback
        when Symbol
          ->(_method, owner, record) { owner.send(callback, record) }
        when Proc
          ->(_method, owner, record) { callback.call(owner, record) }
        else
          ->(method, owner, record) { callback.send(method, owner, record) }
        end
      end
      model.send("#{full_callback_name}=", callbacks)
    end

    def self.wrap_scope(scope, mod)
      if scope
        if scope.arity.positive?
          proc { |owner| instance_exec(owner, &scope).extending(mod) }
        else
          proc { instance_exec(&scope).extending(mod) }
        end
      else
        proc { extending(mod) }
      end
    end
  end
end
