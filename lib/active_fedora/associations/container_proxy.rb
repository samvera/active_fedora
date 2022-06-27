# frozen_string_literal: true
module ActiveFedora
  module Associations
    class ContainerProxy < CollectionProxy
      def initialize(association)
        @association = association
        super
      end
    end
  end
end
