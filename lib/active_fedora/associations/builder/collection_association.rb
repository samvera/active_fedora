module ActiveFedora::Associations::Builder
  class CollectionAssociation < Association #:nodoc:
    CALLBACKS = [:before_add, :after_add, :before_remove, :after_remove]

    self.valid_options += [ 
      :before_add, :after_add, :before_remove, :after_remove
    ]


    def self.build(model, name, options)
      new(model, name, options).build
    end

    def initialize(model, name, options)
      super(model, name, options)
    end

    def build
      reflection = super
      CALLBACKS.each { |callback_name| define_callback(callback_name) }
      reflection
    end

    def writable?
      true
    end

    private

      def define_callback(callback_name)
        full_callback_name = "#{callback_name}_for_#{name}"

        # TODO : why do i need method_defined? I think its because of the inheritance chain
        model.class_attribute full_callback_name.to_sym unless model.method_defined?(full_callback_name)
        model.send("#{full_callback_name}=", Array(options[callback_name.to_sym]))
      end

      def define_readers
        super

        name = self.name
        mixin.redefine_method("#{name.to_s.singularize}_ids") do
          association(name).ids_reader
        end
      end

      def define_writers
        super

        name = self.name
        mixin.redefine_method("#{name.to_s.singularize}_ids=") do |ids|
          association(name).ids_writer(ids)
        end
      end
  end
end
