module ActiveFedora
  module Associations
    class AssociationScope #:nodoc:

      attr_reader :association
      
      delegate :klass, :owner, :reflection, :interpolate, :to => :association
      delegate :chain, :scope_chain, :options, :source_options, :active_record, :to => :reflection

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
          is_first_chain = i == 0
          klass = is_first_chain ? self.klass : reflection.klass
          scope.where_values[options[:property]] = owner.id
        end

        scope
      end

    end
  end
end
