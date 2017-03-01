module ActiveFedora::Associations
  ##
  # An association type validator which does no validation.
  class NullValidator
    def self.validate!(_reflection, _object); end
  end
end
