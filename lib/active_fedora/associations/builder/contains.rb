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
      if options[:class_name] && !options[:class_name].is_a?(String)
        raise ArgumentError, ":class_name must be a string for contains '#{name}'" unless options[:class_name].is_a? String
      end
    end

    def self.define_readers(mixin, name)
      mixin.send(:define_method, name) do |*params|
        association(name).reader(*params).tap do |file|
          set_uri = uri.kind_of?(RDF::URI) ? uri.value.present? : uri.present?
          if set_uri
            file_uri = "#{uri}/#{name}"
            file.uri = file_uri
            file.exists! if contains_assertions.include?(file_uri)
          end
        end
      end
    end
  end
end

