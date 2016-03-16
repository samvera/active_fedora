module ActiveFedora
  module SolrQueryBuilder
    PARSED_SUFFIX = '_tesim'.freeze

    class << self
      # Construct a solr query for a list of ids
      # This is used to get a solr response based on the list of ids in an object's RELS-EXT relationhsips
      # If the id_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
      # @param [Array] id_array the ids that you want included in the query
      def construct_query_for_ids(id_array)
        ids = id_array.reject(&:blank?)
        return "id:NEVER_USE_THIS_ID" if ids.empty?
        "{!terms f=#{ActiveFedora.id_field}}#{ids.join(',')}"
      end

      # Create a raw query clause suitable for sending to solr as an fq element
      # @param [String] key
      # @param [String] value
      def raw_query(key, value)
        Deprecation.warn(ActiveFedora::Base, 'ActiveFedora::SolrQueryBuilder.raw_query is deprecated and will be removed in ActiveFedora 10.0. Use .construct_query instead.')
        "_query_:\"{!raw f=#{key}}#{value.gsub('"', '\"')}\""
      end

      # @deprecated
      def solr_name(*args)
        Deprecation.warn(ActiveFedora::Base, 'ActiveFedora::SolrQueryBuilder.solr_name is deprecated and will be removed in ActiveFedora 10.0. Use ActiveFedora.index_field_mapper.solr_name instead.')
        ActiveFedora.index_field_mapper.solr_name(*args)
      end

      # Create a query with a clause for each key, value
      # @param [Hash, Array<Array<String>>] field_pairs key is the predicate, value is the target_uri
      # @param [String] join_with ('AND') the value we're joining the clauses with
      # @example
      #   construct_query_for_rel [[:has_model, "info:fedora/afmodel:ComplexCollection"], [:has_model, "info:fedora/afmodel:ActiveFedora_Base"]], 'OR'
      #   # => _query_:"{!raw f=has_model_ssim}info:fedora/afmodel:ComplexCollection" OR _query_:"{!raw f=has_model_ssim}info:fedora/afmodel:ActiveFedora_Base"
      #
      #   construct_query_for_rel [[Book.reflect_on_association(:library), "foo/bar/baz"]]
      def construct_query_for_rel(field_pairs, join_with = ' AND ')
        field_pairs = field_pairs.to_a if field_pairs.is_a? Hash
        construct_query(property_values_to_solr(field_pairs), join_with)
      end

      # Construct a solr query from a list of pairs (e.g. [field name, values])
      # @param [Array<Array>] field_pairs a list of pairs of property name and values
      # @param [String] join_with ('AND') the value we're joining the clauses with
      # @return [String] a solr query
      # @example
      #   construct_query([['library_id_ssim', '123'], ['owner_ssim', 'Fred']])
      #   # => "_query_:\"{!raw f=library_id_ssim}123\" AND _query_:\"{!raw f=owner_ssim}Fred\""
      def construct_query(field_pairs, join_with = ' AND ')
        pairs_to_clauses(field_pairs).join(join_with)
      end

      private

        # @param [Array<Array>] pairs a list of (key, value) pairs. The value itself may
        # @return [Array] a list of solr clauses
        def pairs_to_clauses(pairs)
          pairs.flat_map do |field, value|
            condition_to_clauses(field, value)
          end
        end

        # @param [String] field
        # @param [String, Array<String>] values
        # @return [Array<String>]
        def condition_to_clauses(field, values)
          values = Array(values)
          values << nil if values.empty?
          values.map do |value|
            if value.present?
              if parsed?(field)
                # If you do a raw query on a parsed field you won't get the matches you expect.
                "#{field}:#{solr_escape(value)}"
              else
                raw_query(field, value)
              end
            else
              # Check that the field is not present. In SQL: "WHERE field IS NULL"
              "-#{field}:[* TO *]"
            end
          end
        end

        def parsed?(field)
          field.end_with?(PARSED_SUFFIX)
        end

        # Adds esaping for spaces which are not handled by RSolr.solr_escape
        # See rsolr/rsolr#101
        def solr_escape(terms)
          RSolr.solr_escape(terms).gsub(/\s+/, "\\ ")
        end

        # Given a list of pairs (e.g. [field name, values]), convert the field names
        # to solr names
        # @param [Array<Array>] pairs a list of pairs of property name and values
        # @return [Hash] map of solr fields to values
        # @example
        #   property_values_to_solr([['library_id', '123'], ['owner', 'Fred']])
        #   # => [['library_id_ssim', '123'], ['owner_ssim', 'Fred']]
        def property_values_to_solr(pairs)
          pairs.each_with_object([]) do |(property, value), list|
            list << [solr_field(property), value]
          end
        end

        # @param [String, ActiveFedora::Relation] field
        # @return [String] the corresponding solr field for the string
        def solr_field(field)
          case field
          when ActiveFedora::Reflection::AssociationReflection
            field.solr_key
          else
            ActiveFedora.index_field_mapper.solr_name(field, :symbol)
          end
        end
    end
  end
end
