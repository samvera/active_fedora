require 'active_support/core_ext/hash/keys'

module ActiveFedora
  module AttributeAssignment
    include ActiveModel::ForbiddenAttributesProtection

    # Alias for assign_attributes.
    def attributes=(attributes)
      assign_attributes(attributes)
    end

    # Allows you to set all the attributes by passing in a hash of attributes with
    # keys matching the attribute names.
    #
    # If the passed hash responds to <tt>permitted?</tt> method and the return value
    # of this method is +false+ an <tt>ActiveModel::ForbiddenAttributesError</tt>
    # exception is raised.
    #
    #   class Cat
    #     include ActiveModel::AttributeAssignment
    #     attr_accessor :name, :status
    #   end
    #
    #   cat = Cat.new
    #   cat.assign_attributes(name: "Gorby", status: "yawning")
    #   cat.name # => 'Gorby'
    #   cat.status => 'yawning'
    #   cat.assign_attributes(status: "sleeping")
    #   cat.name # => 'Gorby'
    #   cat.status => 'sleeping'
    def assign_attributes(new_attributes)
      unless new_attributes.respond_to?(:stringify_keys)
        raise ArgumentError, "When assigning attributes, you must pass a hash as an argument."
      end
      return if new_attributes.nil? || new_attributes.empty?

      attributes = new_attributes.stringify_keys
      _assign_attributes(sanitize_for_mass_assignment(attributes))
    end

    private

      def _assign_attributes(attributes)
        attributes.each do |k, v|
          _assign_attribute(k, v)
        end
      end

      def _assign_attribute(k, v)
        raise UnknownAttributeError.new(self, k) unless respond_to?("#{k}=")
        public_send("#{k}=", v)
      end
  end
end
