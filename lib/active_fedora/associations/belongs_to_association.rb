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

          ### TODO a more efficient way of doing this would be to write a clear_relationship method
          old_record = find_target
          @owner.remove_relationship(@reflection.options[:property], old_record) unless old_record.nil?

          @target = (AssociationProxy === record ? record.target : record)
          @owner.add_relationship(@reflection.options[:property], record) unless record.new_record?
          @updated = true
        end

        loaded
        record
      end

      private
        def find_target
          pid = @owner.ids_for_outbound(@reflection.options[:property]).first
          return if pid.nil?
          query = ActiveFedora::SolrService.construct_query_for_pids([pid])
          solr_result = SolrService.query(query) 
          return ActiveFedora::SolrService.reify_solr_results(solr_result).first
        end

        def foreign_key_present
          !@owner.send(@reflection.primary_key_name).nil?
        end

    end
  end
end
