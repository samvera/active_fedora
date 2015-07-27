module ActiveFedora::Associations
  ##
  # An association type validator which does no validation.
  class NullValidator
    def self.validate!(reflection, object)
    end
  end
end
