module ActiveFedora
  module Rdf
    module NestedAttributes
      extend ActiveSupport::Concern

      included do
        class_attribute :nested_attributes_options, :instance_writer => false
        self.nested_attributes_options = {}
      end

      private

      UNASSIGNABLE_KEYS = %w(_destroy )

      # @param [Symbol] association_name
      # @param [Hash, Array] attributes_collection
      # @example
      #
      #   assign_nested_attributes_for_collection_association(:people, {
      #     '1' => { id: '1', name: 'Peter' },
      #     '2' => { name: 'John' },
      #     '3' => { id: '2', _destroy: true }
      #   })
      #
      # Will update the name of the Person with ID 1, build a new associated
      # person with the name 'John', and mark the associated Person with ID 2
      # for destruction.
      #
      # Also accepts an Array of attribute hashes:
      #
      #   assign_nested_attributes_for_collection_association(:people, [
      #     { id: '1', name: 'Peter' },
      #     { name: 'John' },
      #     { id: '2', _destroy: true }
      #   ])
      def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
        options = self.nested_attributes_options[association_name]

        # TODO
        #check_record_limit!(options[:limit], attributes_collection)

        if attributes_collection.is_a?(Hash)
          attributes_collection = attributes_collection.values
        end

        association = self.send(association_name)

        attributes_collection.each do |attributes|
          attributes = attributes.with_indifferent_access
          
          if attributes['id'] && existing_record = association.detect { |record| record.rdf_subject.to_s == attributes['id'].to_s }
            if !call_reject_if(association_name, attributes)
              assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])
            end
          else
            attributes = attributes.with_indifferent_access
            association.build(attributes.except(*UNASSIGNABLE_KEYS))
          end
        end
      end

      # Updates a record with the +attributes+ or marks it for destruction if
      # +allow_destroy+ is +true+ and has_destroy_flag? returns +true+.
      def assign_to_or_mark_for_destruction(record, attributes, allow_destroy)
        record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
        record.mark_for_destruction if has_destroy_flag?(attributes) && allow_destroy
      end

      def call_reject_if(association_name, attributes)
        return false if has_destroy_flag?(attributes)
        case callback = self.nested_attributes_options[association_name][:reject_if]
        when Symbol
          method(callback).arity == 0 ? send(callback) : send(callback, attributes)
        when Proc
          callback.call(attributes)
        end
      end

      # Determines if a hash contains a truthy _destroy key.
      def has_destroy_flag?(hash)
        ["1", "true"].include?(hash['_destroy'].to_s)
      end
      

      module ClassMethods
        def accepts_nested_attributes_for *attr_names
          options = { :allow_destroy => false, :update_only => false }
          options.update(attr_names.extract_options!)
          options.assert_valid_keys(:allow_destroy, :reject_if, :limit, :update_only)
          options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

          attr_names.each do |association_name|
            nested_attributes_options = self.nested_attributes_options.dup
            nested_attributes_options[association_name] = options
            self.nested_attributes_options = nested_attributes_options

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
              assign_nested_attributes_for_collection_association(:#{association_name}, attributes)
              ## in lieu of autosave_association_callbacks just save all of em.
              send(:#{association_name}).each {|obj| obj.marked_for_destruction? ? obj.destroy : nil}
              send(:#{association_name}).reset!
            end
          eoruby
        end
      end
    end
  end
end
