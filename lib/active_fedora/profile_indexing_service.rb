module ActiveFedora
  class ProfileIndexingService
    def initialize(object)
      @object = object
    end

    def export
      @object.serializable_hash.to_json
    end
  end
end
