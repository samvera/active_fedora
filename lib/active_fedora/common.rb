module ActiveFedora
  module Common
    extend ActiveSupport::Concern
    include Pathing

    module ClassMethods
      def initialize_generated_modules # :nodoc:
        generated_association_methods
      end

      def generated_association_methods
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          include mod
          mod
        end
      end
    end

    ##
    # @return [String] the etag from the response headers
    #
    # @raise [RuntimeError] when the resource is new and has no etag
    # @raise [Ldp::Gone]    when the resource is deleted
    def etag
      raise 'Unable to produce an etag for a unsaved object' if ldp_source.new?
      ldp_source.head.etag
    end

    def ldp_source
      @ldp_source
    end

    # Returns true if +comparison_object+ is the same exact object, or +comparison_object+
    # is of the same type and +self+ has an ID and it is equal to +comparison_object.id+.
    #
    # Note that new records are different from any other record by definition, unless the
    # other record is the receiver itself.
    #
    # Note also that destroying a record preserves its ID in the model instance, so deleted
    # models are still comparable.
    def ==(other)
      other.equal?(self) ||
        (other.instance_of?(self.class) &&
          !id.nil? &&
          other.id == id)
    end

    # Allows sort on objects
    def <=>(other)
      if other.is_a?(self.class)
        to_key <=> other.to_key
      else
        super
      end
    end

    # Freeze datastreams such that they can be loaded from Fedora, but can't be changed
    def freeze
      @frozen = true
    end

    def frozen?
      @frozen.present?
    end

    # Returns +true+ if the record is read only. Records loaded through joins with piggy-back
    # attributes will be marked as read only since they cannot be saved.
    def readonly?
      @readonly
    end

    # Marks this record as read only.
    def readonly!
      @readonly = true
    end
  end
end
