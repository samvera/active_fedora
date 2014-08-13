module ActiveFedora::Associations::Builder
  class BelongsTo < SingularAssociation #:nodoc:
    self.macro = :belongs_to

    self.valid_options += [:touch]

    def build
      reflection = super
      add_counter_cache_callbacks(reflection) if options[:counter_cache]
      add_touch_callbacks(reflection)         if options[:touch]
      # predicate_lens = FedoraLens::Lenses.get_predicate(predicate, select: filter_by_class(reflection))
      # model.attribute :"#{name}_id", [ predicate_lens, FedoraLens::Lenses.uris_to_ids { reflection.klass }, FedoraLens::Lenses.single ]
      model.property :"#{name}_id", predicate: predicate
      configure_dependency
      reflection
    end

    # TODO this is a huge waste of time that can be completely avoided if the attributes aren't sharing predicates.
    def filter_by_class(reflection)
      lambda do |obj|
        id = reflection.klass.uri_to_id(obj)
        results = ActiveFedora::SolrService.query(ActiveFedora::SolrService.construct_query_for_pids([id]))

        results.any? do |result|
          ActiveFedora::SolrService.classes_from_solr_document(result).any? { |klass|
            class_ancestors(klass).include? reflection.klass
          }
        end
      end
    end

    private

      ##
      # Returns a list of all the ancestor classes up to ActiveFedora::Base including the class itself
      # @param [Class] klass
      # @return [Array<Class>]
      # @example
      #   class Car < ActiveFedora::Base; end
      #   class SuperCar < Car; end
      #   class_ancestors(SuperCar)
      #   # => [SuperCar, Car, ActiveFedora::Base]
      def class_ancestors(klass)
        klass.ancestors.select {|k| k.instance_of?(Class) } - [Object, BasicObject]
      end

      def add_counter_cache_callbacks(reflection)
        cache_column = reflection.counter_cache_column
        name         = self.name

        method_name = "belongs_to_counter_cache_after_create_for_#{name}"
        mixin.redefine_method(method_name) do
          record = send(name)
          record.class.increment_counter(cache_column, record.id) unless record.nil?
        end
        model.after_create(method_name)

        method_name = "belongs_to_counter_cache_before_destroy_for_#{name}"
        mixin.redefine_method(method_name) do
          record = send(name)
          record.class.decrement_counter(cache_column, record.id) unless record.nil?
        end
        model.before_destroy(method_name)

        model.send(:module_eval,
          "#{reflection.class_name}.send(:attr_readonly,\"#{cache_column}\".intern) if defined?(#{reflection.class_name}) && #{reflection.class_name}.respond_to?(:attr_readonly)", __FILE__, __LINE__
        )
      end

      def add_touch_callbacks(reflection)
        name        = self.name
        method_name = "belongs_to_touch_after_save_or_destroy_for_#{name}"
        touch       = options[:touch]

        mixin.redefine_method(method_name) do
          record = send(name)

          unless record.nil?
            if touch == true
              record.touch
            else
              record.touch(touch)
            end
          end
        end

        model.after_save(method_name)
        model.after_touch(method_name)
        model.after_destroy(method_name)
      end

      def configure_dependency
        if options[:dependent]
          unless [:destroy, :delete].include?(options[:dependent])
            raise ArgumentError, "The :dependent option expects either :destroy or :delete (#{options[:dependent].inspect})"
          end

          method_name = "belongs_to_dependent_#{options[:dependent]}_for_#{name}"
          model.send(:class_eval, <<-eoruby, __FILE__, __LINE__ + 1)
            def #{method_name}
              association = #{name}
              association.#{options[:dependent]} if association
            end
          eoruby
          model.after_destroy method_name
        end
      end

      # A bit of a misnomer because this is actually defining readers and writers
      def define_readers
        super
        # model.attribute "#{name}_id", [predicate, FedoraLens::Lenses.single, FedoraLens::Lenses.literal_to_string]
        model.property :"#{name}_id", predicate: predicate
      end
  end
end
