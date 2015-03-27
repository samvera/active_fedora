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
        # Copied from ActiveRecord.  This workaround should not be required
        # after ruby 1.9 support is ended.
        if Module.methods_transplantable?
          # See define_method_attribute in read.rb for an explanation of
          # this code.
          def define_method_attribute=(name)
            method = WriterMethodCache[name.to_s]
            generated_attribute_methods.module_eval {
              define_method "#{name}=", method
            }
          end
        else
          def define_method_attribute=(name)
            safe_name = name.unpack('h*').first
            ActiveFedora::AttributeMethods::AttrNames.set_name_cache safe_name, name

            generated_attribute_methods.module_eval <<-EOMETHOD, __FILE__, __LINE__ + 1
              def __temp__#{safe_name}=(value)
                name = ::ActiveFedora::AttributeMethods::AttrNames::ATTR_#{safe_name}
                write_attribute(name, value)
              end
              alias_method #{(name + '=').inspect}, :__temp__#{safe_name}=
              undef_method :__temp__#{safe_name}=
            EOMETHOD
          end
        end





      end # end classmethods

    end
  end
end
