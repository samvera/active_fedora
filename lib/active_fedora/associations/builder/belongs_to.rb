# frozen_string_literal: true
module ActiveFedora::Associations::Builder
  class BelongsTo < SingularAssociation # :nodoc:
    def self.macro
      :belongs_to
    end

    def self.valid_options(options)
      super + [:optional]
    end

    def self.valid_dependent_options
      %i[destroy delete]
    end

    def self.validate_options(options)
      super
      raise "You must specify a predicate for #{name}" unless options[:predicate]
      raise ArgumentError, "Predicate must be a kind of RDF::URI" unless options[:predicate].is_a?(RDF::URI)
    end

    def self.define_validations(model, reflection)
      reflection.options[:optional] = !reflection.options.delete(:required) if reflection.options.key?(:required)

      required = if reflection.options[:optional].nil?
                   model.belongs_to_required_by_default
                 else
                   !reflection.options[:optional]
                 end

      super

      model.validates_presence_of reflection.name, message: :required if required
    end
  end
end
