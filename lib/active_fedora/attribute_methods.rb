require 'active_support/core_ext/object'
require 'active_support/core_ext/class/attribute'

module ActiveFedora
  module AttributeMethods
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    AttrNames = Module.new {
      def self.set_name_cache(name, value)
        const_name = "ATTR_#{name}"
        unless const_defined? const_name
          const_set const_name, value.dup.freeze
        end
      end
    }

    class AttributeMethodCache
      def initialize
        @module = Module.new
        @method_cache = ThreadSafe::Cache.new
      end

      def [](name)
        @method_cache.compute_if_absent(name) do
          safe_name = name.unpack('h*').first
          temp_method = "__temp__#{safe_name}"
          ActiveFedora::AttributeMethods::AttrNames.set_name_cache safe_name, name
          @module.module_eval method_body(temp_method, safe_name), __FILE__, __LINE__
          @module.instance_method temp_method
        end
      end

      private
      def method_body; raise NotImplementedError; end
    end


    included do
      initialize_generated_modules
      include Read
      include Write
      include Dirty
    end

    # Returns an array of names for the attributes available on this object.
    #
    #   class Person < ActiveFedora::Base
    #   end
    #
    #   person = Person.new
    #   person.attribute_names
    #   # => ["id", "created_at", "updated_at", "name", "age"]
    def attribute_names
      @attributes.keys
    end

    # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
    #
    #   class Person < ActiveFedora::Base
    #   end
    #
    #   person = Person.create(name: 'Francesco', age: 22)
    #   person.attributes
    #   # => {"id"=>3, "created_at"=>Sun, 21 Oct 2012 04:53:04, "updated_at"=>Sun, 21 Oct 2012 04:53:04, "name"=>"Francesco", "age"=>22}
    def attributes
      attribute_names.each_with_object({}) { |name, attrs|
        attrs[name] = read_attribute(name)
      }
    end


    # Returns the value of the attribute identified by <tt>attr_name</tt> after it has been typecast (for example,
    # "2004-12-12" in a date column is cast to a date object, like Date.new(2004, 12, 12)). It raises
    # <tt>ActiveModel::MissingAttributeError</tt> if the identified attribute is missing.
    #
    # Alias for the <tt>read_attribute</tt> method.
    #
    #   class Person < ActiveRecord::Base
    #     belongs_to :organization
    #   end
    #
    #   person = Person.new(name: 'Francesco', age: '22')
    #   person[:name] # => "Francesco"
    #   person[:age]  # => 22
    #
    #   person = Person.select('id').first
    #   person[:name]            # => ActiveModel::MissingAttributeError: missing attribute: name
    #   person[:organization_id] # => ActiveModel::MissingAttributeError: missing attribute: organization_id
    def [](attr_name)
      read_attribute(attr_name) { |n| missing_attribute(n, caller) }
    end

    # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
    # (Alias for the protected <tt>write_attribute</tt> method).
    #
    #   class Person < ActiveFedora::Base
    #   end
    #
    #   person = Person.new
    #   person[:age] = '22'
    #   person[:age] # => 22
    #   person[:age] # => Fixnum
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end

    module ClassMethods
      def initialize_generated_modules # :nodoc:
        @generated_attribute_methods = Module.new { extend Mutex_m }
        include @generated_attribute_methods
      end
      private
        # @param name [Symbol] name of the attribute to generate
        def generate_method(name)
          generated_attribute_methods.synchronize do
            define_attribute_methods name
          end
        end
    end
  end
end
