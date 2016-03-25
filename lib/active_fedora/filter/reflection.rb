module ActiveFedora::Filter
  class Reflection < ActiveFedora::Reflection::AssociationReflection
    def association_class
      Association
    end

    # delegates to extending_from
    def klass
      extending_from.klass
    end

    def extending_from
      @extending_from ||= active_fedora._reflect_on_association(options.fetch(:extending_from))
    end

    def collection?
      true
    end
  end
end

