module ActiveFedora::Filter
  class Reflection < ActiveFedora::Reflection::AssociationReflection
    def macro
      :filter
    end

    def association_class
      Association
    end

    # delegates to extending_from
    delegate :klass, to: :extending_from

    def extending_from
      @extending_from ||= active_fedora._reflect_on_association(options.fetch(:extending_from))
    end

    def collection?
      true
    end
  end
end
