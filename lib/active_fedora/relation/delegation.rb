module ActiveFedora
  module Delegation # :nodoc:
    extend ActiveSupport::Concern

    # This module creates compiled delegation methods dynamically at runtime, which makes
    # subsequent calls to that method faster by avoiding method_missing. The delegations
    # may vary depending on the klass of a relation, so we create a subclass of Relation
    # for each different klass, and the delegations are compiled into that subclass only.

    delegate :length, :map, :to_ary, :[], :&, :|, :+, :-, :sample, :reverse, :rotate, :compact, :shuffle, :slice, :index, :rindex, :size, to: :to_a
    delegate :any?, :all?, :collect, :include?, to: :each
  end
end
