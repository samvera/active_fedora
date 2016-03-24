module ActiveFedora::Associations
  class OrdersAssociation < ::ActiveFedora::Associations::CollectionAssociation
    def initialize(*args)
      super
      @target = find_target
    end

    def inspect
      "#<ActiveFedora::Associations::OrdersAssociation:#{object_id}>"
    end

    def reader(*args)
      @proxy ||= ActiveFedora::Orders::CollectionProxy.new(self)
      @null_proxy ||= ActiveFedora::Orders::CollectionProxy.new(self)
      super
    end

    # Meant to override all nodes with the given nodes.
    # @param [Array<ActiveFedora::Base>] nodes Nodes to set as ordered members
    def target_writer(nodes)
      target_reader.clear
      target_reader.concat(nodes)
      target_reader
    end

    def target_reader
      @target_proxy ||= ActiveFedora::Orders::TargetProxy.new(self)
    end

    def target_ids_reader
      target_reader.ids
    end

    def find_reflection
      reflection
    end

    def replace(new_ordered_list)
      raise unless new_ordered_list.is_a? ActiveFedora::Orders::OrderedList
      list_container.ordered_self = new_ordered_list
      @target = find_target
    end

    def find_target
      ordered_proxies
    end

    def load_target
      @target = find_target
    end

    # Append a target node to the end of the order.
    # @param [ActiveFedora::Base] record Record to append
    def append_target(record, _skip_callbacks = false)
      unless unordered_association.target.include?(record)
        unordered_association.concat(record)
      end
      target.append_target(record, proxy_in: owner)
    end

    # Insert a target node in a specific position
    # @param [Integer] loc Position to insert record.
    # @param [ActiveFedora::Base] record Record to insert
    def insert_target_at(loc, record)
      unless unordered_association.target.include?(record)
        unordered_association.concat(record)
      end
      target.insert_at(loc, record, proxy_in: owner)
    end

    # Insert a target ID in a specific position
    # @param [Integer] loc Position to insert record ID
    # @param [String] id ID of record to insert.
    def insert_target_id_at(loc, id)
      raise ArgumentError, "ID can not be nil" if id.nil?
      unless unordered_association.ids_reader.include?(id)
        raise ArgumentError, "#{id} is not a part of #{unordered_association.reflection.name}"
      end
      target.insert_proxy_for_at(loc, ActiveFedora::Base.id_to_uri(id), proxy_in: owner)
    end

    # Delete whatever node is at a specific position
    # @param [Integer] loc Position to delete
    delegate :delete_at, to: :target

    # Delete all occurences of the specified target
    # @param obj object to delete
    delegate :delete_target, to: :target

    # Delete multiple list nodes.
    # @param [Array<ActiveFedora::Orders::ListNode>] records
    def delete_records(records, _method = nil)
      records.each do |record|
        delete_record(record)
      end
    end

    # Delete a list node
    # @param [ActiveFedora::Orders::ListNode] record Node to delete.
    def delete_record(record)
      target.delete_node(record)
    end

    def insert_record(record, _force = true, _validate = true)
      record.save_target
      list_container.save
      # NOTE: This turns out to be pretty cheap, but should we be doing it
      # elsewhere?
      unless list_container.changed?
        owner.head = [list_container.head_id.first]
        owner.tail = [list_container.tail_id.first]
        owner.save
      end
    end

    def scope(*_args)
      @scope ||= ActiveFedora::Relation.new(klass)
    end

    private

      def ordered_proxies
        list_container.ordered_self
      end

      def create_list_node(record)
        node = ListNode.new(RDF::URI.new("#{list_container.uri}##{::RDF::Node.new.id}"), list_container.resource)
        node.proxyIn = owner
        node.proxyFor = record
        node
      end

      def association_scope
        nil
      end

      def list_container
        list_container_association.reader
      end

      def list_container_association
        owner.association(options[:through])
      end

      def unordered_association
        owner.association(unordered_reflection_name)
      end

      def unordered_reflection_name
        reflection.unordered_reflection.name
      end
  end
end
