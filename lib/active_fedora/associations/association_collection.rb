module ActiveFedora
  module Associations
    class AssociationCollection < AssociationProxy #:nodoc:
      def initialize(owner, reflection)
        super
      end

      # Returns the size of the collection 
      #
      # If the collection has been already loaded +size+ and +length+ are
      # equivalent. If not and you are going to need the records anyway
      # +length+ will take one less query. Otherwise +size+ is more efficient.
      #
      # This method is abstract in the sense that it relies on
      # +count_records+, which is a method descendants have to provide.
      def size
        if @owner.new_record? && @target
          @target.size
        elsif !loaded? && @target.is_a?(Array)
          unsaved_records = @target.select { |r| r.new_record? }
          unsaved_records.size + count_records
        else
          count_records
        end
      end
      

      def to_ary
        load_target
        if @target.is_a?(Array)
          @target.to_ary
        else
          Array.wrap(@target)
        end
      end
      alias_method :to_a, :to_ary

      # Add +records+ to this association.  Returns +self+ so method calls may be chained.
      # Since << flattens its argument list and inserts each record, +push+ and +concat+ behave identically.
      def <<(*records)
        result = true
        load_target if @owner.new_record?

        flatten_deeper(records).each do |record|
          raise_on_type_mismatch(record)
          add_record_to_target_with_callbacks(record) do |r|
            result &&= insert_record(record) unless @owner.new_record?
          end
        end

        result && self
      end

      alias_method :push, :<<
      alias_method :concat, :<<
      

      def load_target
        if !@owner.new_record?
          begin
            if !loaded?
              if @target.is_a?(Array) && @target.any?
                @target = find_target.map do |f|
                  i = @target.index(f)
                  if i
                    @target.delete_at(i).tap do |t|
                      keys = ["id"] + t.changes.keys + (f.attribute_names - t.attribute_names)
                      t.attributes = f.attributes.except(*keys)
                    end
                  else
                    f
                  end
                end + @target
              else
                @target = find_target
              end
            end
          rescue ActiveRecord::RecordNotFound
            reset
          end
        end

        loaded if target
        target
      end

      def find_target
        @owner.load_inbound_relationship(@reflection.options[:property])
      end


      def add_record_to_target_with_callbacks(record)
      #  callback(:before_add, record)
        yield(record) if block_given?
        @target ||= [] unless loaded?
        if index = @target.index(record)
          @target[index] = record
        else
           @target << record
        end
      #  callback(:after_add, record)
      #  set_inverse_instance(record, @owner)
        record
      end

      
    end
  end
end
