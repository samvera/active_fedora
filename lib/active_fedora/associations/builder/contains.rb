module ActiveFedora::Associations::Builder
  class Contains < SingularAssociation #:nodoc:
    self.macro = :contains
    self.valid_options += [:autocreate, :block]

    def initialize(model, name, options)
      super
      options[:class_name] = 'ActiveFedora::File' if options[:class_name].blank?
    end

    def validate_options
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
