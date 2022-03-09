module ActiveFedora
  module AttributeMethods
    module Read
      module ClassMethods
        protected

          # Please be aware that this can vary based upon the Rails release used
          # @see https://github.com/rails/rails/blob/6-1-stable/activemodel/lib/active_model/attribute_methods.rb#L297
          def define_method_attribute(name, **options)
            name = name.to_s
            safe_name = name.unpack('h*'.freeze).first
            temp_method = "__temp__#{safe_name}"

            ActiveFedora::AttributeMethods::AttrNames.set_name_cache safe_name, name

            generated_attribute_methods.module_eval <<-STR, __FILE__, __LINE__ + 1
              def #{temp_method}
                name = ::ActiveRecord::AttributeMethods::AttrNames::ATTR_#{safe_name}
                _read_attribute(name) { |n| missing_attribute(n, caller) }
              end
            STR

            generated_attribute_methods.module_eval do
              alias_method name, temp_method
              undef_method temp_method
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
