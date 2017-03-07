module ActiveFedora
  module Inheritance
    extend ActiveSupport::Concern

    module ClassMethods
      # Returns the class descending directly from ActiveFedora::Base, or
      # an abstract class, if any, in the inheritance hierarchy.
      #
      # If A extends ActiveFedora::Base, A.base_class will return A. If B descends from A
      # through some arbitrarily deep hierarchy, B.base_class will return A.
      #
      # If B < A and C < B and if A is an abstract_class then both B.base_class
      # and C.base_class would return B as the answer since A is an abstract_class.
      def base_class
        return File if self <= File

        unless self <= Base
          raise ActiveFedoraError, "#{name} doesn't belong in a hierarchy descending from ActiveFedora"
        end

        if self == Base || superclass == Base || superclass.abstract_class?
          self
        else
          superclass.base_class
        end
      end

      # Abstract classes can't have default scopes.
      def abstract_class?
        self == Base
      end
    end
  end
end
