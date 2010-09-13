require 'solr'
require "solrizer/field_name_mapper"

module ActiveFedora
  class SolrService 
      
    attr_reader :conn
        
    def self.register(host=nil, args={})
      Thread.current[:solr_service]=self.new(host, args)

    end
    def initialize(host, args)
      host = 'http://localhost:8080/solr' unless host
      opts = {:autocommit=>:on}.merge(args)
      @conn = Solr::Connection.new(host, opts)
    end
    
    def self.instance
      raise SolrNotInitialized unless Thread.current[:solr_service]
      Thread.current[:solr_service]
    end
    
    def self.reify_solr_results(solr_result)
      unless solr_result.is_a?(Solr::Response::Standard)
        raise ArgumentError.new("Only solr responses (Solr::Response::Standard) are allowed. You provided a #{solr_result.class}")
      end
      results = []
      solr_result.hits.each do |hit|
        model_value = hit[Solrizer::FieldNameMapper.solr_name("active_fedora_model", :symbol)].first
        if model_value.include?("::")
          classname = eval(model_value)
        else
          classname = Kernel.const_get(model_value)
        end
        results << Fedora::Repository.instance.find_model(hit[SOLR_DOCUMENT_ID], classname)
      end
      return results
    end
    
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
    
    def self.mappings
      Solrizer::FieldNameMapper.mappings
    end
    def self.mappings=(mappings)
      Solrizer::FieldNameMapper.mappings = mappings
    end
        
    def self.logger      
      @logger ||= defined?(RAILS_DEFAULT_LOGGER) ? RAILS_DEFAULT_LOGGER : Logger.new(STDOUT)
    end
    
    # (re)load solr field name mappings
    def self.load_mappings( config_path=nil )
      Solrizer::FieldNameMapper.load_mappings(config_path)
    end
    
  class SolrNotInitialized < StandardError;end
end #SolrService
end #ActiveFedora
