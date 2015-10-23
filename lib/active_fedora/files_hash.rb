module ActiveFedora
  class FilesHash < AssociationHash
    def initialize(model)
      @base = model
    end

    def reflections
      @base.class.child_resource_reflections
    end

    def keys
      reflections.keys + @base.undeclared_files
    end
  end
end
