module ActiveFedora
  module Scoping
    extend ActiveSupport::Concern
    included do
      include Default
      include Named
    end

    
    module ClassMethods
      def current_scope #:nodoc:
        Thread.current["#{self}_current_scope"]
      end

      def current_scope=(scope) #:nodoc:
        Thread.current["#{self}_current_scope"] = scope
      end
    end
  end
end
