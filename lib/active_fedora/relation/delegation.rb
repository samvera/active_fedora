module ActiveFedora
  module Delegation # :nodoc:
    extend ActiveSupport::Concern

    # This module creates compiled delegation methods dynamically at runtime, which makes
    # subsequent calls to that method faster by avoiding method_missing. The delegations
    # may vary depending on the klass of a relation, so we create a subclass of Relation
    # for each different klass, and the delegations are compiled into that subclass only.
    
    delegate :length, :collect, :map, :each, :all?, :include?, :to_ary, :to => :to_a


    def method_missing(method, *args, &block)
      if Array.method_defined?(method)
        self.class.delegate method, :to => :to_a
        to_a.send(method, *args, &block)
      else
        super
      end
    end
  end
end
