# frozen_string_literal: true
module ActiveFedora
  module Associations
    class SingularAssociation < Association # :nodoc:
      # Implements the reader method, e.g. foo.bar for Foo.has_one :bar
      def reader(force_reload = false)
        raise NotImplementedError, "Need to define the uncached method" if force_reload # TODO

        reload if !loaded? || stale_target?
        target
      end

      # Implements the writer method, e.g. foo.items= for Foo.has_many :items
      def writer(record)
        replace(record)
      end

      def create(attributes = {})
        new_record(:create, attributes)
      end

      def create!(attributes = {})
        build(attributes).tap(&:save!)
      end

      def build(attributes = {})
        new_record(:build, attributes)
      end

      private

        def find_target
          # TODO: this forces a solr query, but I think it's likely we can just lookup from Fedora.
          # See https://github.com/samvera/active_fedora/issues/1330
          rec = scope.take
          rec.tap { |record| set_inverse_instance(record) }
        end

        # Implemented by subclasses
        def replace(_record)
          raise NotImplementedError
        end

        def new_record(method, attributes)
          attributes = {} # scoped.scope_for_create.merge(attributes || {})
          record = @reflection.send("#{method}_association", attributes)
          replace(record)
          record
        end
    end
  end
end
