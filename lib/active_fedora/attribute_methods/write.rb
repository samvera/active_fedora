module ActiveFedora
  module AttributeMethods
    module Write
      module ClassMethods
        protected

          def define_method_attribute=(name, owner: nil, as: name) # rubocop:disable Lint/UnusedMethodArgument
            name = name.to_s
            safe_name = name.unpack('h*'.freeze).first
            ActiveFedora::AttributeMethods::AttrNames.set_name_cache safe_name, name

            generated_attribute_methods.module_eval <<-STR, __FILE__, __LINE__ + 1
              def __temp__#{safe_name}=(value)
                name = ::ActiveRecord::AttributeMethods::AttrNames::ATTR_#{safe_name}
                write_attribute(name, value)
              end
              alias_method #{(name + '=').inspect}, :__temp__#{safe_name}=
              undef_method :__temp__#{safe_name}=
            STR
          end
      end

      extend ActiveSupport::Concern

      included do
        attribute_method_suffix "="
      end

      def write_attribute(attribute_name, value)
        raise ActiveModel::MissingAttributeError, "can't write unknown attribute `#{attribute_name}'" unless self.class.properties.key?(attribute_name)

        attributes[attribute_name] = value
      end

      private

        def attribute=(attribute_name, value)
          write_attribute(attribute_name, value)
        end
    end
  end
end
