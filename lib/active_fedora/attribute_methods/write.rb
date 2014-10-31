module ActiveFedora
  module AttributeMethods
    module Write
      WriterMethodCache = Class.new(AttributeMethodCache) {
        private

        def method_body(method_name, const_name)
          <<-EOMETHOD
          def #{method_name}(value)
            name = ::ActiveFedora::AttributeMethods::AttrNames::ATTR_#{const_name}
            write_attribute(name, value)
          end
          EOMETHOD
        end
      }.new

      extend ActiveSupport::Concern

      included do
        attribute_method_suffix "="
      end

      def write_attribute(attribute_name, value)
        if self.class.properties.key?(attribute_name)
          @attributes[attribute_name] = value
        else
          raise ActiveModel::MissingAttributeError, "can't write unknown attribute `#{attribute_name}'"
        end
      end

      private
        def attribute=(attribute_name, value)
          write_attribute(attribute_name, value)
        end

      module ClassMethods
        def define_method_attribute=(name)
          method = WriterMethodCache[name.to_s]
          generated_attribute_methods.module_eval {
            define_method "#{name}=", method
          }
        end
      end

    end
  end
end
