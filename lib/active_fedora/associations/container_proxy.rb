module ActiveFedora
  module Associations
    class ContainerProxy < CollectionProxy
      # rubocop:disable Lint/MissingSuper
      def initialize(association)
        @association = association
      end
      # rubocop:enable Lint/MissingSuper
    end
  end
end
