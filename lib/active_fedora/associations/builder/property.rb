module ActiveFedora::Associations::Builder
  class Property < Association

    self.macro = :rdf
    self.valid_options = [:class_name, :property, :predicate]

    def initialize(model, name, options)
      super
      @name = :"#{name.to_s.singularize}_ids"
    end

  end
end

