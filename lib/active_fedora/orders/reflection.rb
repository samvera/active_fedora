module ActiveFedora::Orders
  class Reflection < ActiveFedora::Reflection::AssociationReflection
    class << self
      def create(macro, name, scope, options, active_fedora)
        klass = case macro
                  when :aggregation
                    Reflection
                  when :filter
                    ActiveFedora::Filter::Reflection
                  when :orders
                    ActiveFedora::Orders::Reflection
                  end
        reflection = klass.new(macro, name, scope, options, active_fedora)
        ActiveFedora::Reflection.add_reflection(active_fedora, name, reflection)
        reflection
      end
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

