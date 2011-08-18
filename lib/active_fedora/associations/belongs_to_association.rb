module ActiveFedora
  module Associations
    class BelongsToAssociation < AssociationProxy #:nodoc:
      def replace(record)
        if record.nil?
          ### TODO a more efficient way of doing this would be to write a clear_relationship method
          old_record = find_target
          @owner.remove_relationship(@reflection.options[:property], old_record) unless old_record.nil?
        else
          raise_on_type_mismatch(record)

          @target = (AssociationProxy === record ? record.target : record)
          @owner.add_relationship(@reflection.options[:property], record) unless record.new_record?
          @updated = true
        end

        loaded
        record
      end

      private
        def find_target
          @owner.load_outbound_relationship(@reflection.options[:property]).first
        end

        def foreign_key_present
          !@owner.send(@reflection.primary_key_name).nil?
        end

    end
  end
end
