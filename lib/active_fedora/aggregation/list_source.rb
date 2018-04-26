module ActiveFedora
  module Aggregation
    class ListSource < ActiveFedora::Base
      delegate :order_will_change!, to: :ordered_self
      property :head, predicate: ::RDF::Vocab::IANA['first'], multiple: false
      property :tail, predicate: ::RDF::Vocab::IANA.last, multiple: false
      property :nodes, predicate: ::RDF::Vocab::DC.hasPart

      def save(*args)
        return true if has_unpersisted_proxy_for? || !changed?
        persist_ordered_self if ordered_self.changed?
        super
      end

      # Overriding so that we don't track previously_changed, which was
      # rather expensive.
      def clear_changed_attributes
        clear_changes_information
      end

      def changed?
        super || ordered_self.changed?
      end

      # Ordered list representation of proxies in graph.
      # @return [Array<ListNode>]
      def ordered_self
        @ordered_self ||= ordered_list_factory.new(resource, head_subject, tail_subject)
      end

      # Allow this to be set so that -=, += will work.
      # @param [ActiveFedora::Orders::OrderedList] An ordered list object this
      #   graph should contain.
      attr_writer :ordered_self

      # Serializing head/tail/nodes slows things down CONSIDERABLY, and is not
      # useful.
      # @note This method is used by ActiveFedora::Base upstream for indexing,
      #   at https://github.com/projecthydra/active_fedora/blob/master/lib/active_fedora/profile_indexing_service.rb.
      def serializable_hash(_options = nil)
        {}
      end

      def to_solr(solr_doc = {})
        super.merge(ordered_targets_ssim: ordered_self.target_ids,
                    proxy_in_ssi: ordered_self.proxy_in.to_s)
      end

      # Not useful and slows down indexing.
      def create_date
        nil
      end

      # Not useful, slows down indexing.
      def modified_date
        nil
      end

      # Not useful, slows down indexing.
      def has_model
        ["ActiveFedora::Aggregation::ListSource"]
      end

      private

        def persist_ordered_self
          nodes_will_change!
          # Delete old statements
          subj = resource.subjects.to_a.select { |x| x.to_s.split("/").last.to_s.include?("#g") }
          subj.each do |s|
            resource.delete [s, nil, nil]
          end
          # Assert head and tail
          self.head = ordered_self.head.next.rdf_subject
          self.tail = ordered_self.tail.prev.rdf_subject
          head_will_change!
          tail_will_change!
          graph = ordered_self.to_graph
          resource << graph
          # Set node subjects to a term in AF JUST so that AF will persist the
          # sub-graphs.
          # TODO: Find a way to fix this.
          resource.set_value(:nodes, [])
          self.nodes += graph.subjects.to_a
          ordered_self.changes_committed!
        end

        def has_unpersisted_proxy_for?
          ordered_self.select(&:new_record?).map(&:target).find { |x| x.respond_to?(:uri) }
        end

        def head_subject
          head_id.first
        end

        def tail_subject
          tail_id.first
        end

        def ordered_list_factory
          ActiveFedora::Orders::OrderedList
        end
    end
  end
end
