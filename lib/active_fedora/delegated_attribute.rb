module ActiveFedora
  # Represents the mapping between a model attribute and a property
  class DelegatedAttribute
    attr_accessor :field, :multiple

    def initialize(field, args = {})
      self.field = field
      self.multiple = args.fetch(:multiple, false)
    end
  end
end
