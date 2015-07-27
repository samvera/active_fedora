module ActiveFedora::Associations::Builder
  class Property < Association

    self.macro = :rdf
    self.valid_options = [:class_name, :predicate, :type_validator]

    def initialize(model, name, options)
      super
      @name = :"#{name.to_s.singularize}_ids"
    end

    def build
      super.tap do |reflection|
        model.index_config[name] = build_index_config(reflection)
      end
    end

    def build_index_config(reflection)
      ActiveFedora::Indexing::Map::IndexObject.new(reflection.predicate_for_solr) { |index| index.as :symbol }
    end

  end
end

