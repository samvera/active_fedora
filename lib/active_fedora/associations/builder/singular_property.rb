module ActiveFedora::Associations::Builder
  class SingularProperty < Property
    def self.macro
      :singular_rdf
    end

    def initialize(model, name, options)
      super
      @name = :"#{name}_id"
    end
  end
end
