module ActiveFedora::Orders
  class Reflection < ActiveFedora::Reflection::AssociationReflection
    def macro
      :orders
    end

    def association_class
      Association
    end

    def collection?
      true
    end

    def class_name
      klass.to_s
    end

    def unordered_reflection
      options[:unordered_reflection]
    end

    def klass
      ActiveFedora::Orders::ListNode
    end
  end
end
