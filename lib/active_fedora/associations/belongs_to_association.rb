module ActiveFedora
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:

      def id_writer(id)
        @full_result = nil
        remove_matching_property_relationship
        return if id.blank? or id == ActiveFedora::UnsavedDigitalObject::PLACEHOLDER
        @owner.add_relationship(@reflection.options[:property], ActiveFedora::Base.internal_uri(id))
      end

      def id_reader
        begin
          # need to find the id with the correct class
          ids = @owner.ids_for_outbound(@reflection.options[:property])

          return if ids.empty?

          # This incurs a lot of overhead, but it's necessary if the users use one property for more than one association.
          # e.g.
          #   belongs_to :author, property: :has_member, class_name: 'Person'
          #   belongs_to :publisher, property: :has_member
          
          if @owner.reflections.one? { |k, v| v.options[:property] == @reflection.options[:property] }
            @full_results = nil
            ids.first
          else
            @full_results = SolrService.query(construct_query(ids))
            @full_results.first['id'] if @full_results.present?
          end
        end
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
          return unless id_reader

          if @full_result # side-effect from #id_reader
            ActiveFedora::SolrService.reify_solr_results([@full_result]).first
          else
            begin
              ActiveFedora::Base.find(id_reader, cast: true)
            rescue ActiveFedora::ObjectNotFoundError
              nil
            end
          end
        end

        # Constructs a query that checks solr for the correct id & class_name combination
        def construct_query(ids)
          # Some descendants of ActiveFedora::Base are anonymous classes. They don't have names. Filter them out.
          candidate_classes = klass.descendants.select {|d| d.name }
          candidate_classes += [klass] unless klass == ActiveFedora::Base
          model_pairs = candidate_classes.inject([]) { |arr, klass| arr << [:has_model, klass.to_class_uri]; arr }
          '(' + ActiveFedora::SolrService.construct_query_for_pids(ids) + ') AND (' +
              ActiveFedora::SolrService.construct_query_for_rel(model_pairs, 'OR') + ')'
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
