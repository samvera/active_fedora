require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'


module ActiveFedora
  module NestedAttributes #:nodoc:
    class TooManyRecords < RuntimeError
    end

    extend ActiveSupport::Concern
    included do
      class_attribute :nested_attributes_options, :instance_writer => false
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
        options = { :allow_destroy => false, :update_only => false }
        options.update(attr_names.extract_options!)
        options.assert_valid_keys(:allow_destroy, :reject_if, :limit, :update_only)
        options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

        attr_names.each do |association_name|
          if reflection = reflect_on_association(association_name)
            reflection.options[:autosave] = true
            add_autosave_association_callbacks(reflection)
            ## TODO this ought to work, but doesn't seem to do the class inheritance right

            nested_attributes_options = self.nested_attributes_options.dup
            nested_attributes_options[association_name.to_sym] = options
            self.nested_attributes_options = nested_attributes_options

            type = (reflection.collection? ? :collection : :one_to_one)

            # def pirate_attributes=(attributes)
            #   assign_nested_attributes_for_one_to_one_association(:pirate, attributes)
            # end
            class_eval <<-eoruby, __FILE__, __LINE__ + 1
              remove_possible_method(:#{association_name}_attributes=)

              def #{association_name}_attributes=(attributes)
                assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
              end
            eoruby
          elsif reflection = reflect_on_property(association_name)
            resource_class.accepts_nested_attributes_for(association_name, options)

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
    UNASSIGNABLE_KEYS = %w( id _destroy )


    def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
      options = nested_attributes_options[association_name]

      if options[:limit] && attributes_collection.size > options[:limit]
        raise TooManyRecords, "Maximum #{options[:limit]} records are allowed. Got #{attributes_collection.size} records instead."
      end

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
        association.to_a
      else
        attribute_ids = attributes_collection.map {|a| a['id'] || a[:id] }.compact
        attribute_ids.present? ? association.to_a.select{ |x| attribute_ids.include?(x.id)} : []
      end

      attributes_collection.each do |attributes|
        attributes = attributes.with_indifferent_access

        if attributes['id'].blank?
          association.build(attributes.except(*UNASSIGNABLE_KEYS)) unless call_reject_if(association_name, attributes)

        elsif existing_record = existing_records.detect { |record| record.id.to_s == attributes['id'].to_s }
          association.send(:add_record_to_target_with_callbacks, existing_record) if !association.loaded? && !call_reject_if(association_name, attributes)

          if !call_reject_if(association_name, attributes)
            assign_to_or_mark_for_destruction(existing_record, attributes, options[:allow_destroy])
          end

        else
          raise_nested_attributes_record_not_found(association_name, attributes['id'])
        end
      end

    end

    # Updates a record with the +attributes+ or marks it for destruction if
    # +allow_destroy+ is +true+ and has_destroy_flag? returns +true+.
    def assign_to_or_mark_for_destruction(record, attributes, allow_destroy)
      record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
      record.mark_for_destruction if has_destroy_flag?(attributes) && allow_destroy
    end

    # Determines if a hash contains a truthy _destroy key.
    def has_destroy_flag?(hash)
      ["1", "true"].include?(hash['_destroy'].to_s)
    end

    def raise_nested_attributes_record_not_found(association_name, record_id)
      reflection = self.class.reflect_on_association(association_name)
      raise ObjectNotFoundError, "Couldn't find #{reflection.klass.name} with ID=#{record_id} for #{self.class.name} with ID=#{id}"
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

  end
end

  
