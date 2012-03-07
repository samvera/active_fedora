require "solrizer"
require 'rsolr'

module ActiveFedora
  class SolrService 
    
    include Solrizer::FieldNameMapper
    include Loggable
    
    load_mappings
      
    attr_reader :conn

    def self.register(host=nil, args={})
      Thread.current[:solr_service]=self.new(host, args)

    end
    def initialize(host, args)
      host = 'http://localhost:8080/solr' unless host
      args = args.dup
      args.merge!(:url=>host)
      @conn = RSolr.connect args
 #     @conn = Solr::Connection.new(host, opts)
    end
    
    def self.instance
    # Register Solr
        
      unless Thread.current[:solr_service]
        ActiveFedora.load_configs
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
        model_value = hit[solr_name("has_model", :symbol)].first
        Model.from_class_uri(model_value)
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
      return uri.gsub(/(:)/, '\\:')
    end

    def self.query(query, args={})
      raw = args.delete(:raw)
      args = args.merge(:q=>query, :qt=>'standard')
      result = SolrService.instance.conn.get('select', :params=>args)
      return result if raw
      result['response']['docs']
    end

  
end #SolrService
class SolrNotInitialized < StandardError;end
end #ActiveFedora
