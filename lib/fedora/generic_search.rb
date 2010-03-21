# 
#  @Creator Matt Zumwalt, MediaShelf LLC
#  @Copyright Matt Zumwalt, 2007.  All Rights Reserved.
#
 
module Fedora
  class GenericSearch
  
    def initialize(uri, service_name)
      @uri = "#{uri}/#{service_name}"
      @client = HTTPClient.new(@uri)
      @extheader = {'User-Agent'=>"RubyFedora"}
    end
  
    def call_resource
    
    end
  
    # TODO: Handle ruby-tyle params, camel-casing them before passing to call_resource...
    def update_index(params)
      query = {:action=>action,:value=>value,:repositoryName=>repository_name,:indexName=>indexname,:restXslt=>"copyXML"}.merge(params)
      query.merge {:operation> "updateIndex"}
    
      @client.get(@uri, query, @extheader)
      return "update_index Not Implemented."
    end
  
  
    def browse_index(params)
      # Sample: /fedoragsearch/rest?operation=browseIndex&startTerm=&fieldName=PID&termPageSize=20&indexName=FedoraIndex&restXslt=copyXml&resultPageXslt=browseIndexToResultPage
      query = {:startTerm=>URLEncoder.encode(start_term, "UTF-8"),:fieldName=>"",:indexName=>"",:termPageSize=>"", :restXslt=>"copyXml", :resultPageXslt=>""}.merge(params)
      query.merge {:operation> "browseIndex"}
      @client.get(@uri, query, @extheader)
      return "browse_index Not Implemented."
    end
  
    def gfind_objects(params)
      # Sample: /fedoragsearch/rest?operation=gfindObjects&query=test&hitPageSize=10&restXslt=copyXml
      # fieldMaxLength limits the number of characters returned from the value of each object field.
      # Snippets will highlight matched words within the search results.  To keep the xml as simple as possible, set snippetsMax to 0.
      query = {:query=>URLEncoder.encode(query, "UTF-8"),:value=>value,:indexName=>indexname,:hitPageStart=>"",:hitPageSize=>"",:snippetsMax=>"0",:fieldMaxLength=>"",:restXslt=>"copyXML",:resultPageXslt=>""}.merge(params)
      query.merge {:operation> "gfindObjects"}
      @client.get(@uri, query, @extheader)
      return "gfind_objects Not Implemented."
    end
  
    def get_index_info(params)
      # Sample: /fedoragsearch/rest?operation=getIndexInfo&restXslt=copyXml
      query = {:indexName=>"",:restXslt=>"copyXml", :resultPageXslt=>""}.merge(params)
      query.merge {:operation> "getIndexInfo"}
      @client.get(@uri, query, @extheader)
      return "get_index_info Not Implemented."
    end
  
    def get_repository_info(params)
      # Sample: /fedoragsearch/rest?operation=getRepositoryInfo&restXslt=copyXml
      query = {:repositoryName=>"",:restXslt=>"copyXml", :resultPageXslt=>""}.merge(params)
      query.merge {:operation> "getRepositoryInfo"}
      @client.get(@uri, query, @extheader)
      return "get_repository_info Not Implemented."
    end
  
    def configure(params)
      query = {:configName=>""}.merge(params)
      query.merge {:operation> "configure"}
      @client.get(@uri, query, @extheader)
      return "configure Not Implemented."
    end
  
  end
end