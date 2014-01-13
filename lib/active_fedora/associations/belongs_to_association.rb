module ActiveFedora
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:

      def id_writer(id)
        remove_matching_property_relationship
        return if id.blank? or id == ActiveFedora::UnsavedDigitalObject::PLACEHOLDER
        @owner.add_relationship(@reflection.options[:property], ActiveFedora::Base.internal_uri(id))
      end

      def id_reader
        # need to find the id with the correct class
        ids = @owner.ids_for_outbound(@reflection.options[:property])

        return if ids.empty? 
        # This incurs a lot of overhead, but it's necessary if the users use one property for more than one association.
        # e.g.
        #   belongs_to :author, :property=>:has_member, :class_name=>'Person'
        #   belongs_to :publisher, :property=>:has_member
        results = SolrService.query(ActiveFedora::SolrService.construct_query_for_pids(ids))
        results.each do |result|
          return result['id'] if SolrService.class_from_solr_document(result) == klass
        end
        return nil
      end

      def replace(record)
        if record.nil?
          id_writer(nil)
        else
          raise_on_type_mismatch(record)
          id_writer(record.id)
          @updated = true

          #= (AssociationProxy === record ? record.target : record)
        end
        self.target = record

        loaded!
        record
      end

      def reset
        super
        @updated = false
      end

      def updated?
        @updated
      end

      private
        def find_target
          pid = id_reader
          return unless pid
          solr_result = SolrService.query(construct_query(pid)) 
          return ActiveFedora::SolrService.reify_solr_results(solr_result).first
        end

        def construct_query pid
          if klass != ActiveFedora::Base
            clauses = {}  
            clauses[:has_model] = klass.to_class_uri
            query = ActiveFedora::SolrService.construct_query_for_rel(clauses) + " AND (" + ActiveFedora::SolrService.construct_query_for_pids([pid]) + ")"
          else
            query = ActiveFedora::SolrService.construct_query_for_pids(pid)
          end
        end

        def remove_matching_property_relationship
          ids = @owner.ids_for_outbound(@reflection.options[:property])
          return if ids.empty? 
          ids.each do |id|
            result = SolrService.query(ActiveFedora::SolrService.construct_query_for_pids([id]))
            hit = ActiveFedora::SolrService.reify_solr_results(result).first
            # We remove_relationship on subjects that match the same class, or if the subject is nil 
            if hit.class == klass || hit.nil?
              @owner.remove_relationship(@reflection.options[:property], hit)
            end
          end
        end

        def foreign_key_present?
          owner[reflection.foreign_key]
        end

        def stale_state
          owner[reflection.foreign_key]
        end
    end
  end
end
