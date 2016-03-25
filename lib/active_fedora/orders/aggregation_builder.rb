module ActiveFedora::Orders
  class AggregationBuilder < ActiveFedora::Associations::Builder::Association
    def self.valid_options(options)
      [:through, :class_name, :has_member_relation, :type_validator]
    end

    def self.build(model, name, options)
      model.indirectly_contains name, { has_member_relation: has_member_relation(options), through: proxy_class, foreign_key: proxy_foreign_key, inserted_content_relation: inserted_content_relation}.merge(indirect_options(options))
      model.contains contains_key(options), class_name: list_source_class
      model.orders name, through: contains_key(options)
    end

    private

    def self.indirect_options(options)
      {
        class_name: options[:class_name],
        type_validator: options[:type_validator]
      }.select { |k, v| v.present? }
    end

    def self.has_member_relation(options)
      options[:has_member_relation] || ::RDF::DC.hasPart
    end

    def self.inserted_content_relation
      ::RDF::Vocab::ORE::proxyFor
    end

    def self.proxy_class
      "ActiveFedora::Aggregation::Proxy"
    end

    def self.proxy_foreign_key
      :target
    end

    def self.contains_key(options)
      options[:through]
    end

    def self.list_source_class
      "ActiveFedora::Aggregation::ListSource"
    end
  end
end

