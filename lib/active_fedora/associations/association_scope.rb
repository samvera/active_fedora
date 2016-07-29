module ActiveFedora
  module Associations
    class AssociationScope #:nodoc:
      def self.scope(association)
        new(association).scope
      end

      attr_reader :association

      delegate :klass, :owner, :reflection, :interpolate, to: :association
      delegate :chain, :scope_chain, :options, :source_options, :active_record, to: :reflection

      def initialize(association)
        @association = association
      end

      def scope
        scope = klass.unscoped
        add_constraints(scope)
      end

      private

        def add_constraints(scope)
          chain.each_with_index do |reflection, i|
            if reflection.macro == :belongs_to
              # Create a partial solr query using the ids. We may add additional filters such as class_name later
              scope = scope.where(ActiveFedora::SolrQueryBuilder.construct_query_for_ids([owner[reflection.foreign_key]]))
            elsif reflection.macro == :has_and_belongs_to_many
            else
              scope = scope.where(ActiveFedora::SolrQueryBuilder.construct_query_for_rel(association.send(:find_reflection) => owner.id))
            end

            is_first_chain = i.zero?
            is_first_chain ? klass : reflection.klass
          end

          scope
        end
    end
  end
end
