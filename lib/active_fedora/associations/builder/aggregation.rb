module ActiveFedora::Associations::Builder
  class Aggregation < ActiveFedora::Associations::Builder::Association
    def self.valid_options(_options)
      [:through, :class_name, :has_member_relation, :type_validator]
    end

    def self.build(model, name, options)
      model.indirectly_contains name, { has_member_relation: has_member_relation(options), through: proxy_class, foreign_key: proxy_foreign_key, inserted_content_relation: inserted_content_relation }.merge(indirect_options(options))
      model.has_subresource contains_key(options), class_name: list_source_class
      model.orders name, through: contains_key(options)
    end

    def self.indirect_options(options)
      {
        class_name: options[:class_name],
        type_validator: options[:type_validator]
      }.select { |_k, v| v.present? }
    end
    private_class_method :indirect_options

    def self.has_member_relation(options)
      options[:has_member_relation] || ::RDF::Vocab::DC.hasPart
    end
    private_class_method :has_member_relation

    def self.inserted_content_relation
      ::RDF::Vocab::ORE.proxyFor
    end
    private_class_method :inserted_content_relation

    def self.proxy_class
      "ActiveFedora::Aggregation::Proxy"
    end
    private_class_method :proxy_class

    def self.proxy_foreign_key
      :target
    end
    private_class_method :proxy_foreign_key

    def self.contains_key(options)
      options[:through]
    end
    private_class_method :contains_key

    def self.list_source_class
      "ActiveFedora::Aggregation::ListSource"
    end
    private_class_method :list_source_class
  end
end
