module ActiveFedora
  module Associations
    class ContainerProxy < CollectionProxy
      def initialize(association)
        @association = association
      end
    end
  end
end
