module ActiveFedora
  module SolrQueryBuilder
    # Construct a solr query for a list of ids
    # This is used to get a solr response based on the list of ids in an object's RELS-EXT relationhsips
    # If the id_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
    # @param [Array] id_array the ids that you want included in the query
    def self.construct_query_for_ids(id_array)
      ids = id_array.reject { |x| x.blank? }
      return "id:NEVER_USE_THIS_ID" if ids.empty?
      "{!terms f=#{SOLR_DOCUMENT_ID}}#{ids.join(',')}"
    end

    # Create a raw query clause suitable for sending to solr as an fq element
    # @param [String] key
    # @param [String] value
    def self.raw_query(key, value)
      "_query_:\"{!raw f=#{key}}#{value.gsub('"', '\"')}\""
    end

    def self.solr_name(*args)
      Solrizer.default_field_mapper.solr_name(*args)
    end

    # Create a query with a clause for each key, value
    # @param [Hash, Array<Array<String>>] field_pairs key is the predicate, value is the target_uri
    # @param [String] join_with ('AND') the value we're joining the clauses with
    # @example
    #   construct_query_for_rel [[:has_model, "info:fedora/afmodel:ComplexCollection"], [:has_model, "info:fedora/afmodel:ActiveFedora_Base"]], 'OR'
    #   # => _query_:"{!raw f=has_model_ssim}info:fedora/afmodel:ComplexCollection" OR _query_:"{!raw f=has_model_ssim}info:fedora/afmodel:ActiveFedora_Base"
    #
    #   construct_query_for_rel [[Book.reflect_on_association(:library), "foo/bar/baz"]]
    def self.construct_query_for_rel(field_pairs, join_with = 'AND')
      field_pairs = field_pairs.to_a if field_pairs.kind_of? Hash

      clauses = pairs_to_clauses(field_pairs.reject { |_, target_uri| target_uri.blank? })
      clauses.empty? ? "id:NEVER_USE_THIS_ID" : clauses.join(" #{join_with} ".freeze)
    end

    private
      # Given an list of 2 element lists, transform to a list of solr clauses
      def self.pairs_to_clauses(pairs)
        pairs.map do |field, target_uri|
          raw_query(solr_field(field), target_uri)
        end
      end

      # @param [String, ActiveFedora::Relation] field
      # @return [String] the corresponding solr field for the string
      def self.solr_field(field)
        case field
        when ActiveFedora::Reflection::AssociationReflection
          field.solr_key
        else
          solr_name(field, :symbol)
        end
      end
  end
end
