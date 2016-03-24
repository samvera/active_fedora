module ActiveFedora
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:
      def handle_dependency
        target.send(options[:dependent]) if load_target
      end

      def replace(record)
        if record
          raise_on_type_mismatch!(record)
          update_counters_on_replace(record)
          replace_keys(record)
          set_inverse_instance(record)
          @updated = true
        else
          decrement_counters
          remove_keys
        end

        self.target = record
      end

      def reset
        super
        @updated = false
      end

      def updated?
        @updated
      end

      def decrement_counters # :nodoc:
        # noop
      end

      def increment_counters # :nodoc:
        # noop
      end

      private

        def find_target?
          !loaded? && foreign_key_present? && klass
        end

        def update_counters_on_replace(_record)
          # noop
        end

        def replace_keys(record)
          owner[reflection.foreign_key] = record.id
        end

        def remove_keys
          owner[reflection.foreign_key] = nil
        end

        def foreign_key_present?
          owner[reflection.foreign_key]
        end

        # belongs_to is not invertible (unless we implement has_one, then make an exception here)
        def invertible_for?(_)
          false
        end

        def stale_state
          owner[reflection.foreign_key]
        end
    end
  end
end
