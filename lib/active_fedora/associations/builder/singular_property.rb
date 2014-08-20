module ActiveFedora::Associations::Builder
  class SingularProperty < Property

    self.macro = :singular_rdf

    def initialize(model, name, options)
      super
      @name = :"#{name}_id"
    end

  end
end
