require 'active_fedora/associations'
module ActiveFedora::Associations::Builder
  class CollectionAssociation < Association #:nodoc:
    CALLBACKS = [:before_add, :after_add, :before_remove, :after_remove]

    self.valid_options += [
      :before_add, :after_add, :before_remove, :after_remove
    ]

    def self.define_callbacks(model, reflection)
      name = reflection.name
      options = reflection.options
      CALLBACKS.each { |callback_name| define_callback(model, callback_name, name, options) }
    end

    def self.define_callback(model, callback_name, name, options)
      full_callback_name = "#{callback_name}_for_#{name}"

      # TODO : why do i need method_defined? I think its because of the inheritance chain
      model.class_attribute full_callback_name.to_sym unless model.method_defined?(full_callback_name)
      model.send("#{full_callback_name}=", Array(options[callback_name.to_sym]))
    end
  end
end
