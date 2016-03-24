module ActiveFedora::Associations::Builder
  class Orders < ActiveFedora::Associations::Builder::CollectionAssociation
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
      mixin.redefine_method("#{target_accessor(name, pluralize: false)}_ids") do
        association(name).target_ids_reader
      end
      mixin.redefine_method("#{target_accessor(name)}=") do |nodes|
        association(name).target_writer(nodes)
      end
    end

    def self.build(model, name, options)
      options = { unordered_reflection: unordered_reflection(model, name) }.merge(options)
      name = :"ordered_#{name.to_s.singularize}_proxies"
      model.property :head, predicate: ::RDF::Vocab::IANA['first']
      model.property :tail, predicate: ::RDF::Vocab::IANA.last
      model.send(:define_method, :apply_first_and_last) do
        source = send(options[:through])
        source.save
        return if head_ids == source.head_id && tail_ids == source.tail_id
        self.head = source.head_id
        self.tail = source.tail_id
        save! if changed?
      end
      model.include ActiveFedora::Associations::Builder::Orders::FixFirstLast
      super
    end

    module FixFirstLast
      def save(*args)
        super.tap do |result|
          apply_first_and_last if result
        end
      end

      def save!(*args)
        super.tap do |result|
          apply_first_and_last if result
        end
      end
    end

    def self.target_accessor(name, pluralize: true)
      name = name.to_s.gsub("_proxies", "")
      if pluralize
        name.pluralize
      else
        name
      end
    end
    private_class_method :target_accessor

    def self.unordered_reflection(model, original_name)
      model._reflect_on_association(original_name)
    end
    private_class_method :unordered_reflection
  end
end
