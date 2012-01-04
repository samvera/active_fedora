module ActiveFedora
  # = Active Fedora Has And Belongs To Many Association
  module Associations
    class HasAndBelongsToManyAssociation < AssociationCollection #:nodoc:
      def initialize(owner, reflection)
        super
      end

      def find_target
          pids = @owner.ids_for_outbound(@reflection.options[:property])
          return [] if pids.empty?
          query = ActiveFedora::SolrService.construct_query_for_pids(pids)
          solr_result = SolrService.instance.conn.query(query)
          return ActiveFedora::SolrService.reify_solr_results(solr_result)
      end


      # def create(attributes = {})
      #   create_record(attributes) { |record| insert_record(record) }
      # end

      # def create!(attributes = {})
      #   create_record(attributes) { |record| insert_record(record, true) }
      # end

      def columns
        @reflection.columns(@reflection.options[:join_table], "#{@reflection.options[:join_table]} Columns")
      end

      # def reset_column_information
      #   @reflection.reset_column_information
      # end

      # def has_primary_key?
      #   @has_primary_key ||= @owner.connection.supports_primary_key? && @owner.connection.primary_key(@reflection.options[:join_table])
      # end

      protected
        # def construct_find_options!(options)
        #   options[:joins]      = Arel::SqlLiteral.new @join_sql
        #   options[:readonly]   = finding_with_ambiguous_select?(options[:select] || @reflection.options[:select])
        #   options[:select]   ||= (@reflection.options[:select] || Arel::SqlLiteral.new('*'))
        # end

        def count_records
          load_target.size
        end

        def insert_record(record, force = true, validate = true)
          if record.new_record?
            if force
              record.save!
            else
              return false unless record.save(:validate => validate)
            end
          end

          ### TODO save relationship
          @owner.add_relationship(@reflection.options[:property], record)
          record.add_relationship(@reflection.options[:property], @owner)
          record.save
          return true
        end

        def delete_records(records)
          records.each do |r| 
            r.remove_relationship(@reflection.options[:property], @owner)
          end
        end

        def construct_query
          internal_uri = @owner.internal_uri
          escaped_uri = internal_uri.gsub(/(:)/, '\\:')
          @counter_query = @finder_query = "#{@reflection.options[:property]}_s:#{escaped_uri}" 
        end

        def construct_scope
          { :find => {  :conditions => @finder_sql,
                        :joins => @join_sql,
                        :readonly => false,
                        :order => @reflection.options[:order],
                        :include => @reflection.options[:include],
                        :limit => @reflection.options[:limit] } }
        end

        # Join tables with additional columns on top of the two foreign keys must be considered
        # ambiguous unless a select clause has been explicitly defined. Otherwise you can get
        # broken records back, if, for example, the join column also has an id column. This will
        # then overwrite the id column of the records coming back.
        def finding_with_ambiguous_select?(select_clause)
          !select_clause && columns.size != 2
        end

      private
        # def create_record(attributes, &block)
        #   # Can't use Base.create because the foreign key may be a protected attribute.
        #   ensure_owner_is_not_new
        #   if attributes.is_a?(Array)
        #     attributes.collect { |attr| create(attr) }
        #   else
        #     build_record(attributes, &block)
        #   end
        # end

        def record_timestamp_columns(record)
          if record.record_timestamps
            record.send(:all_timestamp_attributes).map { |x| x.to_s }
          else
            []
          end
        end
    end
  end
end
