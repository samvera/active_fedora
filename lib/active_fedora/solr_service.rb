require "solrizer"
require 'rsolr'

module ActiveFedora
  class SolrService 
    
    include Solrizer::FieldNameMapper
    include Loggable
    
    attr_reader :conn

    def self.register(host=nil, args={})
      load_mappings
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
    
    def self.reify_solr_results(solr_result,opts={})
      results = []
      solr_result.each do |hit|
        classname = class_from_solr_document(hit)
        if opts[:load_from_solr]
          results << classname.load_instance_from_solr(hit[SOLR_DOCUMENT_ID])
        else
          results << classname.find(hit[SOLR_DOCUMENT_ID])
        end
      end
      return results
    end
  
    def self.class_from_solr_document(hit)
        model_value = nil
        hit[solr_name("has_model", :symbol)].each {|value| model_value ||= Model.from_class_uri(value)}
        logger.warn "Could not find a model for #{hit["id"]}, defaulting to ActiveFedora::Base" unless model_value
        model_value || ActiveFedora::Base
    end
    
    # Construct a solr query for a list of pids
    # This is used to get a solr response based on the list of pids in an object's RELS-EXT relationhsips
    # If the pid_array is empty, defaults to a query of "id:NEVER_USE_THIS_ID", which will return an empty solr response
    # @param [Array] pid_array the pids that you want included in the query
    def self.construct_query_for_pids(pid_array)
      query = ""
      pid_array.each_index do |i|
        query << "#{SOLR_DOCUMENT_ID}:#{escape_uri_for_query(pid_array[i])}"
        query << " OR " if i != pid_array.length-1
      end
      query = "id:NEVER_USE_THIS_ID" if query.empty? || query == "id:"
      return query
    end
    
    def self.escape_uri_for_query(uri)
      return uri.gsub(/(:)/, '\\:').gsub(/(\/)/, '\\/')
    end
    
    def self.construct_query_for_rel(predicate, target_uri)
      "#{solr_name(predicate, :symbol)}:#{escape_uri_for_query(target_uri)}"
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
    # @returns [Integer] number of records matching
    def self.count(query)
        SolrService.query(query, :raw=>true, :rows=>0)['response']['numFound'].to_i
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
