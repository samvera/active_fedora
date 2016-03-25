module ActiveFedora::Orders
  class Builder < ActiveFedora::Associations::Builder::CollectionAssociation
    include ActiveFedora::AutosaveAssociation::AssociationBuilderExtension
    def self.macro
      :orders
    end

    def self.valid_options(options)
      super + [:through, :unordered_reflection]
    end

    def self.define_readers(mixin, name)
      super
      mixin.redefine_method(target_accessor(name)) do
        association(name).target_reader
      end
      mixin.redefine_method("#{target_accessor(name)}=") do |nodes|
        association(name).target_writer(nodes)
      end
    end

    def self.build(model, name, options)
      options = { unordered_reflection: unordered_reflection(model, name)}.merge(options)
      name = :"ordered_#{name.to_s.singularize}_proxies"
      model.property :head, predicate: ::RDF::Vocab::IANA['first']
      model.property :tail, predicate: ::RDF::Vocab::IANA.last
      model.send(:define_method, :apply_first_and_last) do
        source = send(options[:through])
        source.save
        return if head.map(&:rdf_subject) == source.head_id && tail.map(&:rdf_subject) == source.tail_id
        self.head = source.head_id
        self.tail = source.tail_id
        save! if changed?
      end
      model.include ActiveFedora::Orders::Builder::FixFirstLast
      super
    end

    def self.create_reflection(model, name, scope, options, extension = nil)
      unless name.is_a?(Symbol)
        name = name.to_sym
        Deprecation.warn(ActiveFedora::Base, "association names must be a Symbol")
      end
      validate_options(options)
      translate_property_to_predicate(options)

      scope = build_scope(scope, extension)
      name = better_name(name)

      ActiveFedora::Orders::Reflection.create(macro, name, scope, options, model)
    end

    module FixFirstLast
      def save(*args)
        super.tap do |result|
          if result
            apply_first_and_last
          end
        end
      end
      def save!(*args)
        super.tap do |result|
          if result
            apply_first_and_last
          end
        end
      end
    end

    private

    def self.target_accessor(name)
      name.to_s.gsub("_proxies","").pluralize
    end

    def self.unordered_reflection(model, original_name)
      model._reflect_on_association(original_name)
    end
  end
end

