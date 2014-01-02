require 'rsolr'

module ActiveFedora
  class SolrService 
    
    include Loggable
    
    attr_reader :conn

    def self.register(host=nil, args={})
      Thread.current[:solr_service]=self.new(host, args)
    end

    def self.reset!
      Thread.current[:solr_service] = nil
    end

    def initialize(host, args)
      host = 'http://localhost:8080/solr' unless host
      args = {:read_timeout => 120, :open_timeout => 120}.merge(args.dup)
      args.merge!(:url=>host)
      @conn = RSolr.connect args
    end
    
    def self.instance
    # Register Solr
        
      unless Thread.current[:solr_service]
        register(ActiveFedora.solr_config[:url])
      end

      raise SolrNotInitialized unless Thread.current[:solr_service]
      Thread.current[:solr_service]
    end

    def self.lazy_reify_solr_results(solr_results, opts = {})
      Enumerator.new do |yielder|
        solr_results.each do |hit|
          yielder.yield(reify_solr_result(hit, opts))
        end
      end
    end
    
    def self.reify_solr_results(solr_results, opts = {})
      solr_results.collect {|hit| reify_solr_result(hit, opts)}
    end

    def self.reify_solr_result(hit, opts = {})
      klass = class_from_solr_document(hit)
      if opts[:load_from_solr]
        klass.load_instance_from_solr(hit[SOLR_DOCUMENT_ID], hit)
      else
        klass.find(hit[SOLR_DOCUMENT_ID], cast: true)
      end
    end
  
    def self.class_from_solr_document(hit, opts = {})
      #Set the default starting point to the class specified, if available.
      best_model_match = Model.from_class_uri(opts[:class]) unless opts[:class].nil?

      hit[solr_name("has_model", :symbol)].each do |value|

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

      logger.warn "Could not find a model for #{hit["id"]}, defaulting to ActiveFedora::Base" unless best_model_match
      best_model_match || ActiveFedora::Base
    end
    
    # Construct a solr query for a list of pids
    # This is used to get a solr response based on the list of pids in an object's RELS-EXT relationhsips
    # If the pid_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
    # @param [Array] pid_array the pids that you want included in the query
    def self.construct_query_for_pids(pid_array)

      q = pid_array.reject { |x| x.empty? }.map do |pid|
        "_query_:\"{!raw f=#{SOLR_DOCUMENT_ID}}#{pid.gsub('"', '\"')}\""
      end

      return "id:NEVER_USE_THIS_ID" if q.empty?

      return q.join(" OR ")
    end

    def self.solr_name(*args)
      Solrizer.default_field_mapper.solr_name(*args)
    end
    
    def self.escape_uri_for_query(uri)
      return uri.gsub(/(:)/, '\\:').gsub(/(\/)/, '\\/')
    end
    
    # Create a query with a clause for each key, value
    # @param [Hash] args key is the predicate, value is the target_uri
    def self.construct_query_for_rel(args)
      clauses = args.map do |predicate, target_uri|
        "_query_:\"{!raw f=#{solr_name(predicate, :symbol)}}#{target_uri.gsub('"', '\"')}\""
      end
      clauses.join(" AND ")
    end

    def self.query(query, args={})
      raw = args.delete(:raw)
      args = args.merge(:q=>query, :qt=>'standard')
      result = SolrService.instance.conn.get('select', :params=>args)
      return result if raw
      result['response']['docs']
    end

    # Get the count of records that match the query
    # @param [String] query a solr query 
    # @param [Hash] args arguments to pass through to `args' param of SolrService.query (note that :rows will be overwritten to 0)
    # @return [Integer] number of records matching
    def self.count(query, args={})
      args = args.merge(:raw=>true, :rows=>0)
      SolrService.query(query, args)['response']['numFound'].to_i
    end

    def self.add(doc)
      SolrService.instance.conn.add(doc)
    end

    def self.commit
      SolrService.instance.conn.commit
    end

  
end #SolrService
class SolrNotInitialized < StandardError;end
end #ActiveFedora
