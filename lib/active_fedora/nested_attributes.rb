require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'

module ActiveFedora
  module NestedAttributes #:nodoc:
    class TooManyRecords < RuntimeError
    end

    extend ActiveSupport::Concern
    included do
      class_attribute :nested_attributes_options, instance_writer: false
      self.nested_attributes_options = {}
    end

    # Defines an attributes writer for the specified association(s). If you
    # are using <tt>attr_protected</tt> or <tt>attr_accessible</tt>, then you
    # will need to add the attribute writer to the allowed list.
    #
    # Supported options:
    # [:allow_destroy]
    #   If true, destroys any members from the attributes hash with a
    #   <tt>_destroy</tt> key and a value that evaluates to +true+
    #   (eg. 1, '1', true, or 'true'). This option is off by default.
    # [:reject_if]
    #   Allows you to specify a Proc or a Symbol pointing to a method
    #   that checks whether a record should be built for a certain attribute
    #   hash. The hash is passed to the supplied Proc or the method
    #   and it should return either +true+ or +false+. When no :reject_if
    #   is specified, a record will be built for all attribute hashes that
    #   do not have a <tt>_destroy</tt> value that evaluates to true.
    #   Passing <tt>:all_blank</tt> instead of a Proc will create a proc
    #   that will reject a record where all the attributes are blank.
    # [:limit]
    #   Allows you to specify the maximum number of the associated records that
    #   can be processed with the nested attributes. If the size of the
    #   nested attributes array exceeds the specified limit, NestedAttributes::TooManyRecords
    #   exception is raised. If omitted, any number associations can be processed.
    #   Note that the :limit option is only applicable to one-to-many associations.
    # [:update_only]
    #   Allows you to specify that an existing record may only be updated.
    #   A new record may only be created when there is no existing record.
    #   This option only works for one-to-one associations and is ignored for
    #   collection associations. This option is off by default.
    #
    # Examples:
    #   # creates avatar_attributes=
    #   accepts_nested_attributes_for :avatar, :reject_if => proc { |attributes| attributes['name'].blank? }
    #   # creates avatar_attributes=
    #   accepts_nested_attributes_for :avatar, :reject_if => :all_blank
    #   # creates avatar_attributes= and posts_attributes=
    #   accepts_nested_attributes_for :avatar, :posts, :allow_destroy => true
    module ClassMethods
      REJECT_ALL_BLANK_PROC = proc { |attributes| attributes.all? { |key, value| key == '_destroy' || value.blank? } }

      def accepts_nested_attributes_for(*attr_names)
        options = { allow_destroy: false, update_only: false }
        options.update(attr_names.extract_options!)
        options.assert_valid_keys(:allow_destroy, :reject_if, :limit, :update_only)
        options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

        attr_names.each do |association_name|
          if reflection = _reflect_on_association(association_name)
            reflection.autosave = true
            define_autosave_association_callbacks(reflection)
            ## TODO this ought to work, but doesn't seem to do the class inheritance right

            nested_attributes_options = self.nested_attributes_options.dup
            nested_attributes_options[association_name.to_sym] = options
            self.nested_attributes_options = nested_attributes_options

            type = (reflection.collection? ? :collection : :one_to_one)
            generate_association_writer(association_name, type)

            class_eval <<-eoruby, __FILE__, __LINE__ + 1
              remove_possible_method(:#{association_name}_attributes=)

              def #{association_name}_attributes=(attributes)
                assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
              end
            eoruby
          elsif reflect_on_property(association_name)
            resource_class.accepts_nested_attributes_for(association_name, options)
            generate_property_writer(association_name, type)

            # Delegate the setter to the resource.
            class_eval <<-eoruby, __FILE__, __LINE__ + 1
              remove_possible_method(:#{association_name}_attributes=)

              def #{association_name}_attributes=(attributes)
                attribute_will_change!(:#{association_name})
                resource.#{association_name}_attributes=(attributes)
              end
            eoruby
          else
            raise ArgumentError, "No association found for name `#{association_name}'. Has it been defined yet?"
          end
        end
      end

      private

        # Generates a writer method for this association. Serves as a point for
        # accessing the objects in the association. For example, this method
        # could generate the following:
        #
        #   def pirate_attributes=(attributes)
        #     assign_nested_attributes_for_one_to_one_association(:pirate, attributes)
        #   end
        #
        # This redirects the attempts to write objects in an association through
        # the helper methods defined below. Makes it seem like the nested
        # associations are just regular associations.
        def generate_association_writer(association_name, type)
          generated_association_methods.module_eval <<-eoruby, __FILE__, __LINE__ + 1
            if method_defined?(:#{association_name}_attributes=)
              remove_method(:#{association_name}_attributes=)
            end
            def #{association_name}_attributes=(attributes)
              assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
            end
          eoruby
        end

        # Generates a writer method for this association. Serves as a point for
        # accessing the objects in the association. For example, this method
        # could generate the following:
        #
        #   def pirate_attributes=(attributes)
        #     assign_nested_attributes_for_one_to_one_association(:pirate, attributes)
        #   end
        #
        # This redirects the attempts to write objects in an association through
        # the helper methods defined below. Makes it seem like the nested
        # associations are just regular associations.
        def generate_property_writer(association_name, _type)
          generated_association_methods.module_eval <<-eoruby, __FILE__, __LINE__ + 1
            if method_defined?(:#{association_name}_attributes=)
              remove_method(:#{association_name}_attributes=)
            end
            def #{association_name}_attributes=(attributes)
              attribute_will_change!(:#{association_name})
              resource.#{association_name}_attributes=(attributes)
            end
          eoruby
        end
    end

    # Returns ActiveFedora::Base#marked_for_destruction? It's
    # used in conjunction with fields_for to build a form element for the
    # destruction of this association.
    #
    # See ActionView::Helpers::FormHelper::fields_for for more info.
    def _destroy
      marked_for_destruction?
    end

    private

      # Attribute hash keys that should not be assigned as normal attributes.
      # These hash keys are nested attributes implementation details.
      UNASSIGNABLE_KEYS = %w(id _destroy).freeze

      # Assigns the given attributes to the association.
      #
      # If an associated record does not yet exist, one will be instantiated. If
      # an associated record already exists, the method's behavior depends on
      # the value of the update_only option. If update_only is +false+ and the
      # given attributes include an <tt>:id</tt> that matches the existing record's
      # id, then the existing record will be modified. If no <tt>:id</tt> is provided
      # it will be replaced with a new record. If update_only is +true+ the existing
      # record will be modified regardless of whether an <tt>:id</tt> is provided.
      #
      # If the given attributes include a matching <tt>:id</tt> attribute, or
      # update_only is true, and a <tt>:_destroy</tt> key set to a truthy value,
      # then the existing record will be marked for destruction.
      def assign_nested_attributes_for_one_to_one_association(association_name, attributes)
        options = nested_attributes_options[association_name]

        attributes = attributes.to_h if attributes.respond_to?(:permitted?)
        attributes = attributes.with_indifferent_access
        existing_record = send(association_name)

        if (options[:update_only] || !attributes['id'].blank?) && existing_record &&
           (options[:update_only] || existing_record.id.to_s == attributes['id'].to_s)
          assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy]) unless call_reject_if(association_name, attributes)

        elsif attributes['id'].present?
          raise_nested_attributes_record_not_found!(association_name, attributes['id'])

        elsif !reject_new_record?(association_name, attributes)
          assignable_attributes = attributes.except(*UNASSIGNABLE_KEYS)

          if existing_record && existing_record.new_record?
            existing_record.assign_attributes(assignable_attributes)
            association(association_name).initialize_attributes(existing_record)
          else
            method = "build_#{association_name}"
            if respond_to?(method)
              send(method, assignable_attributes)
            else
              raise ArgumentError, "Cannot build association `#{association_name}'. Are you trying to build a polymorphic one-to-one association?"
            end
          end
        end
      end

      def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
        options = nested_attributes_options[association_name]

        if attributes_collection.respond_to?(:permitted?)
          attributes_collection = attributes_collection.to_h
        end

        unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
          raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
        end

        check_record_limit!(options[:limit], attributes_collection)

        if attributes_collection.is_a? Hash
          keys = attributes_collection.keys
          attributes_collection = if keys.include?('id') || keys.include?(:id)
                                    Array(attributes_collection)
                                  else
                                    attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
                                  end
        end

        association = send(association_name)

        existing_records = if association.loaded?
                             association.target
                           else
                             attribute_ids = attributes_collection.map { |a| a['id'] || a[:id] }.compact
                             attribute_ids.present? ? association.to_a.select { |x| attribute_ids.include?(x.id) } : []
                           end

        attributes_collection.each do |attributes|
          attributes = attributes.to_h if attributes.respond_to?(:permitted)
          attributes = attributes.with_indifferent_access

          if attributes['id'].blank?
            unless reject_new_record?(association_name, attributes)
              association.build(attributes.except(*UNASSIGNABLE_KEYS))
            end

          elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes['id'].to_s }
            association.send(:add_record_to_target_with_callbacks, existing_record) if !association.loaded? && !call_reject_if(association_name, attributes)

            unless call_reject_if(association_name, attributes)
              assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])
            end

          else
            raise_nested_attributes_record_not_found!(association_name, attributes['id'])
          end
        end
      end

      # Takes in a limit and checks if the attributes_collection has too many
      # records. It accepts limit in the form of symbol, proc, or
      # number-like object (anything that can be compared with an integer).
      #
      # Raises TooManyRecords error if the attributes_collection is
      # larger than the limit.
      def check_record_limit!(limit, attributes_collection)
        return unless limit
        limit = case limit
                when Symbol
                  send(limit)
                when Proc
                  limit.call
                else
                  limit
                end

        raise TooManyRecords, "Maximum #{limit} records are allowed. Got #{attributes_collection.size} records instead." if limit && attributes_collection.size > limit
      end

      # Updates a record with the +attributes+ or marks it for destruction if
      # +allow_destroy+ is +true+ and has_destroy_flag? returns +true+.
      def assign_to_or_mark_for_destruction(record, attributes, allow_destroy)
        record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
        record.mark_for_destruction if has_destroy_flag?(attributes) && allow_destroy
      end

      # Determines if a hash contains a truthy _destroy key.
      def has_destroy_flag?(hash)
        Type::Boolean.new.cast(hash['_destroy'])
      end

      # Determines if a new record should be rejected by checking
      # has_destroy_flag? or if a <tt>:reject_if</tt> proc exists for this
      # association and evaluates to +true+.
      def reject_new_record?(association_name, attributes)
        will_be_destroyed?(association_name, attributes) || call_reject_if(association_name, attributes)
      end

      # Determines if a record with the particular +attributes+ should be
      # rejected by calling the reject_if Symbol or Proc (if defined).
      # The reject_if option is defined by +accepts_nested_attributes_for+.
      #
      # Returns false if there is a +destroy_flag+ on the attributes.
      def call_reject_if(association_name, attributes)
        return false if will_be_destroyed?(association_name, attributes)

        opts = nested_attributes_options[association_name]
        case callback = opts[:reject_if]
        when Symbol
          method(callback).arity.zero? ? send(callback) : send(callback, attributes)
        when Proc
          callback.call(attributes)
        end
      end

      # Only take into account the destroy flag if <tt>:allow_destroy</tt> is true
      def will_be_destroyed?(association_name, attributes)
        allow_destroy?(association_name) && has_destroy_flag?(attributes)
      end

      def allow_destroy?(association_name)
        nested_attributes_options[association_name][:allow_destroy]
      end

      def raise_nested_attributes_record_not_found!(association_name, record_id)
        reflection = self.class._reflect_on_association(association_name).klass.name
        raise ObjectNotFoundError, "Couldn't find #{reflection.klass.name} with ID=#{record_id} for #{self.class.name} with ID=#{id}"
      end
  end
end
