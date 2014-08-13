module ActiveFedora
  module AttributeMethods
    module Declarations
      extend ActiveSupport::Concern

      included do
        class_attribute :attributes_as_lenses
        self.attributes_as_lenses = {}.with_indifferent_access
        class << self
          def inherited_with_lenses(kls) #:nodoc:
            ## Do some inheritance logic that doesn't override Base.inherited
            inherited_without_lenses kls
            # each subclass should get a copy of the parent's attributes_as_lenses table,
            # it should not add to the parent's definition table.
            kls.attributes_as_lenses = kls.attributes_as_lenses.dup
          end
          alias_method_chain :inherited, :lenses
        end
      end

      module ClassMethods
        def attribute(name, path)
          raise AttributeNotSupportedException if name.to_sym == :id
          attributes_as_lenses[name] = path.map{|s| coerce_to_lens(s)}
          generate_method(name)
          orm_to_hash = nil # force us to rebuild the aggregate_lens in case it was already built.
        end

        private
          def coerce_to_lens(path_segment)
            if path_segment.is_a? RDF::URI
              Lenses.get_predicate(path_segment)
            else
              path_segment
            end
          end
      end
    end
  end
end
