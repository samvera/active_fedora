module ActiveFedora
  module Core
    extend ActiveSupport::Concern
    
    # Constructor.  You may supply a custom +:pid+, or we call the Fedora Rest API for the
    # next available Fedora pid, and mark as new object.
    # Also, if +attrs+ does not contain +:pid+ but does contain +:namespace+ it will pass the
    # +:namespace+ value to Fedora::Repository.nextid to generate the next pid available within
    # the given namespace.
    def initialize(attributes_or_resource_or_url = nil)
      case attributes_or_resource_or_url
        when Ldp::Resource
          super
        when String
          super(ActiveFedora::Base.id_to_uri(attributes_or_resource_or_url))
        else
          attributes = attributes_or_resource_or_url
          super()
      end

      @association_cache = {}
      load_datastreams
      self.attributes = attributes if attributes
      run_callbacks :initialize
    end

    # Reloads the object from Fedora.
    def reload
      raise ActiveFedora::ObjectNotFoundError, "Can't reload an object that hasn't been saved" unless persisted?
      clear_association_cache
      clear_datastreams
      load_datastreams
      super
      self
    end

    def ==(comparison_object)
         comparison_object.equal?(self) ||
           (comparison_object.instance_of?(self.class) &&
             comparison_object.pid == pid &&
             !comparison_object.new_record?)
    end

    def freeze
      datastreams.freeze
      self
    end

    def frozen?
      datastreams.frozen?
    end

    module ClassMethods
      # Returns a suitable uri object for :has_model
      # Should reverse Model#from_class_uri
      def to_class_uri(attrs = {})
        if self.respond_to? :pid_namespace
          namespace = self.pid_namespace
        else
          namespace = attrs.fetch(:namespace, ActiveFedora::Model::NAMESPACE)
        end
        "info:fedora/#{namespace}:#{sanitized_class_name(self)}" 
      end

      private

      def sanitized_class_name(klass)
        klass.name.gsub(/(::)/, '_')
      end

      def relation
        Relation.new(self)
      end
    end
  end
end
