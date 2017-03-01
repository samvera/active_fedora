module ActiveFedora
  module Associations
    # This is the root class of all associations:
    #
    #   Association
    #     BelongsToAssociation
    #     AssociationCollection
    #       HasManyAssociation
    #
    #
    class Association
      attr_reader :owner, :target, :reflection
      attr_accessor :inversed
      delegate :options, :klass, to: :reflection

      def initialize(owner, reflection)
        reflection.check_validity!
        @owner = owner
        @reflection = reflection
        reset
        reset_scope
      end

      # Resets the \loaded flag to +false+ and sets the \target to +nil+.
      def reset
        @loaded = false
        @target = nil
        @stale_state = nil
        @inversed = false
      end

      # Reloads the \target and returns +self+ on success.
      def reload
        reset
        reset_scope
        load_target
        self unless @target.nil?
      end

      # Has the \target been already \loaded?
      def loaded?
        @loaded
      end

      # Asserts the \target has been loaded setting the \loaded flag to +true+.
      def loaded!
        @loaded = true
        @stale_state = stale_state
        @inversed = false
      end

      # The target is stale if the target no longer points to the record(s) that the
      # relevant foreign_key(s) refers to. If stale, the association accessor method
      # on the owner will reload the target. It's up to subclasses to implement the
      # state_state method if relevant.
      #
      # Note that if the target has not been loaded, it is not considered stale.
      def stale_target?
        !inversed && loaded? && @stale_state != stale_state
      end

      # Sets the target of this proxy to <tt>\target</tt>, and the \loaded flag to +true+.
      def target=(target)
        @target = target
        loaded!
      end

      def scope
        target_scope.merge(association_scope)
      end

      # The scope for this association.
      #
      # Note that the association_scope is merged into the target_scope only when the
      # scope method is called. This is because at that point the call may be surrounded
      # by scope.scoping { ... } or with_scope { ... } etc, which affects the scope which
      # actually gets built.
      def association_scope
        @association_scope ||= AssociationScope.scope(self) if klass
      end

      def reset_scope
        @association_scope = nil
      end

      # Set the inverse association, if possible
      def set_inverse_instance(record)
        return unless record && invertible_for?(record)
        inverse = record.association(inverse_reflection_for(record).name.to_sym)
        if inverse.is_a? ActiveFedora::Associations::HasAndBelongsToManyAssociation
          inverse.target << owner
        else
          inverse.target = owner
        end
        inverse.inversed = true
      end

      # Can be overridden (i.e. in ThroughAssociation) to merge in other scopes (i.e. the
      # through association's scope)
      def target_scope
        klass.all
      end

      # Loads the \target if needed and returns it.
      #
      # This method is abstract in the sense that it relies on +find_target+,
      # which is expected to be provided by descendants.
      #
      # If the \target is already \loaded it is just returned. Thus, you can call
      # +load_target+ unconditionally to get the \target.
      #
      # ActiveFedora::ObjectNotFoundError is rescued within the method, and it is
      # not reraised. The proxy is \reset and +nil+ is the return value.
      def load_target
        @target = find_target if (@stale_state && stale_target?) || find_target?
        loaded! unless loaded?
        target
      rescue ActiveFedora::ObjectNotFoundError
        reset
      end

      def initialize_attributes(record, except_from_scope_attributes = nil) #:nodoc:
        except_from_scope_attributes ||= {}
        skip_assign = [reflection.foreign_key].compact
        assigned_keys = record.changed
        assigned_keys += except_from_scope_attributes.keys.map(&:to_s)
        attributes = create_scope.except(*(assigned_keys - skip_assign))
        record.assign_attributes(attributes)
        set_inverse_instance(record)
      end

      private

        def find_target?
          !loaded? && (!owner.new_record? || foreign_key_present?) && klass
        end

        def creation_attributes
          attributes = {}

          if (reflection.has_one? || reflection.collection?) && !options[:through]
            attributes[reflection.foreign_key] = owner[reflection.active_record_primary_key]

            if reflection.options[:as]
              attributes[reflection.type] = owner.class.base_class.name
            end
          end

          attributes
        end

        # Sets the owner attributes on the given record
        def set_owner_attributes(record)
          creation_attributes.each { |key, value| record[key] = value }
        end

        # Returns true if there is a foreign key present on the owner which
        # references the target. This is used to determine whether we can load
        # the target if the owner is currently a new record (and therefore
        # without a key). If the owner is a new record then foreign_key must
        # be present in order to load target.
        #
        # Currently implemented by belongs_to
        def foreign_key_present?
          false
        end

        # Raises ActiveFedora::AssociationTypeMismatch unless +record+ is of
        # the kind of the class of the associated objects. Meant to be used as
        # a sanity check when you are about to assign an associated record.
        def raise_on_type_mismatch!(record)
          unless record.is_a?(reflection.klass)
            fresh_class = reflection.class_name.safe_constantize
            unless fresh_class && record.is_a?(fresh_class)
              message = "#{reflection.class_name}(##{reflection.klass.object_id}) expected, got #{record.class}(##{record.class.object_id})"
              raise ActiveFedora::AssociationTypeMismatch, message
            end
          end

          type_validator.validate!(self, record)
        end

        def type_validator
          options[:type_validator] || NullValidator
        end

        # Can be redefined by subclasses, notably polymorphic belongs_to
        # The record parameter is necessary to support polymorphic inverses as we must check for
        # the association in the specific class of the record.
        def inverse_reflection_for(_record)
          reflection.inverse_of
        end

        # Returns true if inverse association on the given record needs to be set.
        # This method is redefined by subclasses.
        def invertible_for?(record)
          inverse_reflection_for(record)
        end

        # This should be implemented to return the values of the relevant key(s) on the owner,
        # so that when state_state is different from the value stored on the last find_target,
        # the target is stale.
        #
        # This is only relevant to certain associations, which is why it returns nil by default.
        def stale_state; end

        def build_record(attributes)
          reflection.build_association(attributes) do |record|
            initialize_attributes(record)
          end
        end
    end
  end
end
