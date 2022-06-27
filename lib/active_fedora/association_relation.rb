# frozen_string_literal: true
module ActiveFedora
  class AssociationRelation < Relation
    def initialize(klass, association)
      super(klass)
      @association = association
    end

    def proxy_association
      @association
    end

    private

      def exec_queries
        super.each { |r| @association.set_inverse_instance r }
      end
  end
end
