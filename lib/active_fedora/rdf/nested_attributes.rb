module ActiveFedora
  module Rdf
    module NestedAttributes
      extend ActiveSupport::Concern

      included do
        class_attribute :nested_attributes_options, :instance_writer => false
        self.nested_attributes_options = {}
      end

      private

      UNASSIGNABLE_KEYS = %w( id _destroy )

      def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
        options = self.nested_attributes_options[association_name]

        # TODO
        #check_record_limit!(options[:limit], attributes_collection)

        if attributes_collection.is_a?(Hash) || attributes_collection.is_a?(String)
          attributes_collection = [attributes_collection]
        end

        association = self.send(association_name)

        attributes_collection.each do |attributes|
          if attributes.instance_of? Hash
            attributes = attributes.with_indifferent_access
            association.build(attributes.except(*UNASSIGNABLE_KEYS))
          else
            association.build(attributes)            
          end
        end
      end

      module ClassMethods
        def accepts_nested_attributes_for *relationships
          relationships.each do |association_name|
            nested_attributes_options[association_name] = {}
            generate_association_writer(association_name)
          end
        end

        private

        # Generates a writer method for this association. Serves as a point for
        # accessing the objects in the association. For example, this method
        # could generate the following:
        #
        #   def pirate_attributes=(attributes)
        #     assign_nested_attributes_for_collection_association(:pirate, attributes)
        #   end
        #
        # This redirects the attempts to write objects in an association through
        # the helper methods defined below. Makes it seem like the nested
        # associations are just regular associations.
        def generate_association_writer(association_name)
            class_eval <<-eoruby, __FILE__, __LINE__ + 1
              if method_defined?(:#{association_name}_attributes=)
                remove_method(:#{association_name}_attributes=)
              end
              def #{association_name}_attributes=(attributes)
                unless attributes.nil?
                  assign_nested_attributes_for_collection_association(:#{association_name}, attributes)
                end
              end
            eoruby
        end
      end
    end
  end
end
