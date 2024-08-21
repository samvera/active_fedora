module ActiveFedora
  module AttributeMethods
    module Write
      module ClassMethods
        protected

          def define_method_attribute=(canonical_name, owner: nil, as: canonical_name)
            ActiveModel::AttributeMethods::AttrNames.define_attribute_accessor_method(
              owner, canonical_name, writer: true
            ) do |temp_method_name, attr_name_expr|
              # rubocop:disable Style/LineEndConcatenation
              if ActiveModel.version >= Gem::Version.new('7.0.0')
                owner.define_cached_method(temp_method_name, as: "#{as}=", namespace: :active_fedora) do |batch|
                  batch <<
                    "def #{temp_method_name}(value)" <<
                    "  write_attribute(#{attr_name_expr}, value)" <<
                    "end"
                end
              elsif ActiveModel.version >= Gem::Version.new('6.1.0')
                owner <<
                  "def #{temp_method_name}(value)" <<
                  "  write_attribute(#{attr_name_expr}, value)" <<
                  "end"
              else
                generated_attribute_methods.module_eval <<-RUBY, __FILE__, __LINE__ + 1
                  def #{temp_method_name}(value)
                    name = #{attr_name_expr}
                    write_attribute(name, value)
                  end
                RUBY
              end
              # rubocop:enable Style/LineEndConcatenation
            end
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
