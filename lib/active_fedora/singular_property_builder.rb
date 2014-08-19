module ActiveFedora

  class SingularPropertyBuilder < ActiveFedora::Associations::Builder::Association

    self.macro = :singular_rdf
    self.valid_options = [:class_name, :property]

    def initialize(model, name, options)
      super
      @name = :"#{name}_id"
    end

  end
end
