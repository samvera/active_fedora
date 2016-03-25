module ActiveFedora
  module Orders
    class TargetProxy
      attr_reader :association
      delegate :+, to: :to_a
      def initialize(association)
        @association = association
      end

      def <<(obj)
        association.append_target(obj)
        self
      end

      def concat(objs)
        objs.each do |obj|
          self.<<(obj)
        end
        self
      end

      def insert_at(loc, record)
        association.insert_target_at(loc, record)
        self
      end

      # Deletes the element at the specified index, returning that element, or nil if
      # the index is out of range.
      def delete_at(loc)
        result = association.delete_at(loc)
        if result
          result.target
        end
      end

      # Deletes all items from self that are equal to obj.
      # @param obj the object to remove from the list
      # @return the last deleted item, or nil if no matching item is found
      def delete(obj)
        association.delete_target(obj)
      end

      def clear
        while to_ary.present?
          association.delete_at(0)
        end
      end

      def to_ary
        association.reader.map(&:target).dup
      end
      alias_method :to_a, :to_ary

      def ==(other_obj)
        case other_obj
        when TargetProxy
          super
        when Array
          to_a == other_obj
        end
      end
    end
  end
end
