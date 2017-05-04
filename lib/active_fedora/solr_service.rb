require 'rsolr'

module ActiveFedora
  class SolrService
    attr_reader :options
    attr_writer :conn

    MAX_ROWS = 10_000

    def initialize(options = {})
      @options = { read_timeout: 120, open_timeout: 120, url: 'http://localhost:8080/solr' }.merge(options)
    end

    def conn
      @conn ||= RSolr.connect @options
    end

    class << self
      # @param [Hash] options
      def register(options = {})
        ActiveFedora::RuntimeRegistry.solr_service = new(options)
      end

      def reset!
        ActiveFedora::RuntimeRegistry.solr_service = nil
      end

      def select_path
        ActiveFedora.solr_config.fetch(:select_path, 'select')
      end

      def instance
        # Register Solr

        unless ActiveFedora::RuntimeRegistry.solr_service
          register(ActiveFedora.solr_config)
        end

        ActiveFedora::RuntimeRegistry.solr_service
      end

      def get(query, args = {})
        args = args.merge(q: query, qt: 'standard')
        SolrService.instance.conn.get(select_path, params: args)
      end

      def query(query, args = {})
        Base.logger.warn "Calling ActiveFedora::SolrService.get without passing an explicit value for ':rows' is not recommended. You will end up with Solr's default (usually set to 10)\nCalled by #{caller[0]}" unless args.key?(:rows)
        result = get(query, args)
        result['response']['docs'].map do |doc|
          ActiveFedora::SolrHit.new(doc)
        end
      end

      def delete(id)
        SolrService.instance.conn.delete_by_id(id, params: { 'softCommit' => true })
      end

      # Get the count of records that match the query
      # @param [String] query a solr query
      # @param [Hash] args arguments to pass through to `args' param of SolrService.query (note that :rows will be overwritten to 0)
      # @return [Integer] number of records matching
      def count(query, args = {})
        args = args.merge(rows: 0)
        SolrService.get(query, args)['response']['numFound'].to_i
      end

      # @param [Hash] doc the document to index, or an array of docs
      # @param [Hash] params
      #   :commit => commits immediately
      #   :softCommit => commit to memory, but don't flush to disk
      def add(doc, params = {})
        SolrService.instance.conn.add(doc, params: params)
      end

      def commit
        SolrService.instance.conn.commit
      end
    end
  end # SolrService
end # ActiveFedora
