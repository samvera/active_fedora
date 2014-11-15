require 'rsolr'
require 'deprecation'

module ActiveFedora
  class SolrService
    extend Deprecation

    attr_reader :conn

    def initialize(host, args)
      host = 'http://localhost:8080/solr' unless host
      args = {read_timeout: 120, open_timeout: 120}.merge(args.dup)
      args.merge!(url: host)
      @conn = RSolr.connect args
    end

    class << self
      def register(host=nil, args={})
        Thread.current[:solr_service] = new(host, args)
      end

      def reset!
        Thread.current[:solr_service] = nil
      end

      def instance
      # Register Solr

        unless Thread.current[:solr_service]
          register(ActiveFedora.solr_config[:url])
        end

        raise SolrNotInitialized unless Thread.current[:solr_service]
        Thread.current[:solr_service]
      end

      def lazy_reify_solr_results(solr_results, opts = {})
        Enumerator.new do |yielder|
          solr_results.each do |hit|
            yielder.yield(reify_solr_result(hit, opts))
          end
        end
      end

      def reify_solr_results(solr_results, opts = {})
        solr_results.collect {|hit| reify_solr_result(hit, opts)}
      end

      def reify_solr_result(hit, opts = {})
        klass = class_from_solr_document(hit)
        klass.find(hit[SOLR_DOCUMENT_ID], cast: true)
      end

      #Returns all possible classes for the solr object
      def classes_from_solr_document(hit, opts = {})
        #Add ActiveFedora::Base as never stored in Solr explicitely.
        #classes = [ActiveFedora::Base]
        classes = []

        hit[HAS_MODEL_SOLR_FIELD].each { |value| classes << Model.from_class_uri(value) }

        classes.compact
      end

      #Returns the best singular class for the solr object
      def class_from_solr_document(hit, opts = {})
        #Set the default starting point to the class specified, if available.
        best_model_match = Model.from_class_uri(opts[:class]) unless opts[:class].nil?
        Array(hit[HAS_MODEL_SOLR_FIELD]).each do |value|

          model_value = Model.from_class_uri(value)

          if model_value

            # Set as the first model in case opts[:class] was nil
            best_model_match ||= model_value

            # If there is an inheritance structure, use the most specific case.
            if best_model_match > model_value
              best_model_match = model_value
            end
          end
        end

        ActiveFedora::Base.logger.warn "Could not find a model for #{hit["id"]}, defaulting to ActiveFedora::Base" unless best_model_match if ActiveFedora::Base.logger
        best_model_match || ActiveFedora::Base
      end

      # Construct a solr query for a list of ids
      # This is used to get a solr response based on the list of ids in an object's RELS-EXT relationhsips
      # If the id_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
      # @param [Array] id_array the ids that you want included in the query
      def construct_query_for_ids(id_array)
        q = id_array.reject { |x| x.blank? }.map { |id| raw_query(SOLR_DOCUMENT_ID, id) }
        q.empty? ? "id:NEVER_USE_THIS_ID" : q.join(" OR ".freeze)
      end

      def construct_query_for_pids(id_array)
        Deprecation.warn SolrService, "construct_query_for_pids is deprecated and will be removed in active-fedora 10.0"
        construct_query_for_ids(id_array)
      end

      # Create a raw query clause suitable for sending to solr as an fq element
      # @param [String] key
      # @param [String] value
      def raw_query(key, value)
        "_query_:\"{!raw f=#{key}}#{value.gsub('"', '\"')}\""
      end

      def solr_name(*args)
        Solrizer.default_field_mapper.solr_name(*args)
      end

      # Create a query with a clause for each key, value
      # @param [Hash, Array<Array<String>>] args key is the predicate, value is the target_uri
      # @param [String] join_with ('AND') the value we're joining the clauses with
      # @example
      #   construct_query_for_rel [[:has_model, "info:fedora/afmodel:ComplexCollection"], [:has_model, "info:fedora/afmodel:ActiveFedora_Base"]], 'OR'
      #   # => _query_:"{!raw f=has_model_ssim}info:fedora/afmodel:ComplexCollection" OR _query_:"{!raw f=has_model_ssim}info:fedora/afmodel:ActiveFedora_Base"
      #
      #   construct_query_for_rel [[Book.reflect_on_association(:library), "foo/bar/baz"]]
      def construct_query_for_rel(field_pairs, join_with = 'AND')
        field_pairs = field_pairs.to_a if field_pairs.kind_of? Hash

        clauses = pairs_to_clauses(field_pairs.reject { |_, target_uri| target_uri.blank? })
        clauses.empty? ? "id:NEVER_USE_THIS_ID" : clauses.join(" #{join_with} ".freeze)
      end

      def query(query, args={})
        raw = args.delete(:raw)
        args = args.merge(:q=>query, :qt=>'standard')
        result = SolrService.instance.conn.get('select', :params=>args)
        return result if raw
        result['response']['docs']
      end

      def delete(id)
        SolrService.instance.conn.delete_by_id(id, params: {'softCommit' => true})
      end

      # Get the count of records that match the query
      # @param [String] query a solr query
      # @param [Hash] args arguments to pass through to `args' param of SolrService.query (note that :rows will be overwritten to 0)
      # @return [Integer] number of records matching
      def count(query, args={})
        args = args.merge(:raw=>true, :rows=>0)
        SolrService.query(query, args)['response']['numFound'].to_i
      end

      # @param [Hash] doc the document to index
      # @param [Hash] params
      #   :commit => commits immediately
      #   :softCommit => commit to memory, but don't flush to disk
      def add(doc, params = {})
        SolrService.instance.conn.add(doc, params: params)
      end

      def commit
        SolrService.instance.conn.commit
      end

      private
        # Given an list of 2 element lists, transform to a list of solr clauses
        def pairs_to_clauses(pairs)
          pairs.map do |field, target_uri|
            raw_query(solr_field(field), target_uri)
          end
        end

        # @param [String, ActiveFedora::Relation] field
        # @return [String] the corresponding solr field for the string
        def solr_field(field)
          case field
          when ActiveFedora::Reflection::AssociationReflection
            field.solr_key
          else
            solr_name(field, :symbol)
          end
        end

    end

    HAS_MODEL_SOLR_FIELD = solr_name("has_model", :symbol).freeze

  end #SolrService
  class SolrNotInitialized < StandardError;end
end #ActiveFedora
