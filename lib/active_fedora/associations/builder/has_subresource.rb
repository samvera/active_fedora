module ActiveFedora::Associations::Builder
  class HasSubresource < SingularAssociation #:nodoc:
    def self.macro
      :has_subresource
    end

    def self.valid_options(options)
      super + [:autocreate, :block]
    end

    def self.create_reflection(model, name, scope, options, extension = nil)
      options[:class_name] = 'ActiveFedora::File' if options[:class_name].blank?
      super(model, name, scope, options, extension)
    end

    def self.validate_options(options)
      super
      return unless options[:class_name] && !options[:class_name].is_a?(String)
      raise ArgumentError, ":class_name must be a string for contains '#{name}'"
    end

    def self.define_readers(mixin, name)
      mixin.send(:define_method, name) do |*params|
        association(name).reader(*params).tap do |file|
          set_uri = uri.is_a?(RDF::URI) ? uri.value.present? : uri.present?
          if set_uri
            file_uri = "#{uri}/#{name}"
            begin
              file.uri = file_uri
            rescue ActiveFedora::AlreadyPersistedError
            end
          end
          if file.respond_to?(:exists!)
            file.exists! if contains_assertions.include?(file_uri)
          end
        end
      end
    end
  end
end
