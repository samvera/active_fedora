module ActiveFedora
  module AttributeMethods
    module Read
      module ClassMethods
        protected

          def define_method_attribute(canonical_name, owner: nil, as: canonical_name)
            ActiveModel::AttributeMethods::AttrNames.define_attribute_accessor_method(
              owner, canonical_name
            ) do |temp_method_name, attr_name_expr|
              # rubocop:disable Style/LineEndConcatenation
              if ActiveModel.version >= Gem::Version.new('7.0.0')
                owner.define_cached_method(temp_method_name, as: as, namespace: :active_fedora) do |batch|
                  batch <<
                    "def #{temp_method_name}" <<
                    "  _read_attribute(#{attr_name_expr}) { |n| missing_attribute(n, caller) }" <<
                    "end"
                end
              elsif ActiveModel.version >= Gem::Version.new('6.1.0')
                owner <<
                  "def #{temp_method_name}" <<
                  "  _read_attribute(#{attr_name_expr}) { |n| missing_attribute(n, caller) }" <<
                  "end"
              else
                generated_attribute_methods.module_eval <<-RUBY, __FILE__, __LINE__ + 1
                  def #{temp_method_name}
                    name = #{attr_name_expr}
                    _read_attribute(name) { |n| missing_attribute(n, caller) }
                  end
                RUBY
              end
              # rubocop:enable Style/LineEndConcatenation
            end
          end
      end

      extend ActiveSupport::Concern

      # Returns the value of the attribute identified by <tt>attr_name</tt> after
      # it has been typecast (for example, "2004-12-12" in a date column is cast
      # to a date object, like Date.new(2004, 12, 12)).
      def read_attribute(attr_name, &block)
        name = attr_name.to_s
        _read_attribute(name, &block)
      end

      def _read_attribute(attr_name) # :nodoc:
        attributes.fetch(attr_name.to_s) { |n| yield n if block_given? }
      end

      alias attribute _read_attribute
      private :attribute
    end
  end
end
