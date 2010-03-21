
require 'fedora/base'
require 'fedora/connection'
require 'fedora/formats'
require 'fedora/fedora_object'
require 'fedora/datastream'

module Fedora
  NAMESPACE = "fedora:info/"
  ALL_FIELDS = [
    :pid, :label, :fType, :cModel, :state, :ownerId, :cDate, :mDate, :dcmDate, 
    :bMech, :title, :creator, :subject, :description, :contributor,
    :date, :type, :format, :identifier, :source, :language, :relation, :coverage, :rights 
  ]
  
  class Repository
    
    attr_accessor :repository_name, :base_url, :fedora_version, :pid_namespace, :pid_delimiter
    
    def self.flush
      Thread.current[:repo]=nil
    end
    def self.register(url, surrogate=nil)
      url = url.to_s.chop if url.to_s =~ /\/\Z/
      Thread.current[:repo]= Fedora::Repository.new(url, surrogate)
      begin
        repo = Thread.current[:repo]
        attributes = repo.describe_repository
        repo.repository_name = attributes["repositoryName"].first
        repo.base_url = attributes["repositoryBaseURL"].first
        repo.fedora_version = attributes["repositoryVersion"].first
        repo.pid_namespace = attributes["repositoryPID"].first["PID-namespaceIdentifier"].first
        repo.pid_delimiter = attributes["repositoryPID"].first["PID-delimiter"].first
      rescue
      end
      Thread.current[:repo]
    end
    def self.instance
      raise "did you register a repo?" unless Thread.current[:repo]
      Thread.current[:repo]
    end
    class StringResponse < String
      attr_reader :content_type
      
      def initialize(s, content_type)
        super(s)
        @content_type = content_type
      end
    end
    
    attr_accessor :fedora_url

    def initialize(fedora_url, surrogate=nil)
      @fedora_url = fedora_url.is_a?(URI) ? fedora_url : URI.parse(fedora_url)
      @surrogate = surrogate
      @connection = nil
    end
    
    # Fetch the raw content of either a fedora object or datastream
    def fetch_content(object_uri)
      response = connection.raw_get("#{url_for(object_uri)}?format=xml")
      StringResponse.new(response.body, response.content_type)
    end
    

    
    # Find fedora objects with http://www.fedora.info/wiki/index.php/API-A-Lite_findObjects
    #
    # == Parameters
    # query<String>:: the query string to be sent to Fedora.
    # options<Hash>:: see below
    #
    # == Options<Hash> keys
    # limit<String|Number>:: set the maxResults parameter in fedora
    # select<Symbol|Array>:: the fields to returned.  To include all fields, pass :all as the value.
    #                           The field "pid" is always included.
    #
    # == Examples
    #    find_objects("label=Image1")
    #    find_objects("pid~demo:*", "label=test")
    #    find_objects("label=Image1", :include => :all)
    #    find_objects("label=Image1", :include => [:label])
    #-
    def find_objects(*args)
      raise ArgumentError, "Missing query string" unless args.length >= 1
      options = args.last.is_a?(Hash) ? args.pop : {}
      
      fields = options[:select]
      fields = (fields.nil? || (fields == :all)) ? ALL_FIELDS : ([:pid] + ([fields].flatten! - [:pid]))
      
      query = args.join(' ')
      params = { :resultFormat => 'xml', :query => query }
      params[:maxResults] = options[:limit] if options[:limit]
      params[:sessionToken] = options[:sessionToken] if options[:sessionToken]
      includes = fields.inject("") { |s, f| s += "&#{f}=true"; s }
      
      convert_xml(connection.get("#{fedora_url.path}/objects?#{params.to_fedora_query}#{includes}"))
    end
    def find_model(pid, klazz)
      obj = self.find_objects("pid=#{pid}").first
      doc = REXML::Document.new(obj.object_xml, :ignore_whitespace_nodes=>:all)
      klazz.deserialize(doc)
    end
    
    # Create the given object if it's new (not obtained from a find method).  Otherwise update the object.
    #
    # == Return
    # boolean:: whether the operation is successful
    #-
    def save(object)
      object.new_object? ? create(object) : update(object)
    end

    def nextid
      d = REXML::Document.new(connection.post(fedora_url.path+"/management/getNextPID?xml=true").body)
      d.elements['//pid'].text
    end

  
    def create(object)
      case object
        when Fedora::FedoraObject
          pid = (object.pid ? object : 'new')
          response = connection.post("#{url_for(pid)}?" + object.attributes.to_fedora_query, object.blob)
          if response.code == '201'
            object.pid = extract_pid(response) 
            object.new_object = false
            true
          else
            false
          end
        when Fedora::Datastream
          raise ArgumentError, "Missing dsID attribute" if object.dsid.nil?
          extra_headers = {}
          extra_headers['Content-Type'] = object.attributes[:mimeType] if object.attributes[:mimeType]
          response = connection.post("#{url_for(object)}?" + object.attributes.to_fedora_query, 
            object.blob, extra_headers)
          if response.code == '201'
            object.new_object = false
            true
          else
            false
          end
        else
          raise ArgumentError, "Unknown object type"
      end
      
    end
  
    # Update the given object
    # == Return
    # boolean:: whether the operation is successful
    #-
    def update(object)
      raise ArgumentError, "Missing pid attribute" if object.nil? || object.pid.nil?
      case object
      when Fedora::FedoraObject
        response = connection.put("#{url_for(object)}?" + object.attributes.to_fedora_query)
        response.code == '200' || '307'
      when Fedora::Datastream
        raise ArgumentError, "Missing dsID attribute" if object.dsid.nil?
        response = connection.put("#{url_for(object)}?" + object.attributes.to_fedora_query, object.blob)
        response.code == '200' || '201'
        return response.code
      else
        raise ArgumentError, "Unknown object type"
      end
    end
  
    # Delete the given pid
    # == Parameters
    # object<Object|String>:: The object to delete.  
    #       This can be a uri String ("demo:1", "fedora:info/demo:1") or any object that responds uri method.
    #
    # == Return
    # boolean:: whether the operation is successful
    #-
    def delete(object)
      raise ArgumentError, "Object must not be nil" if object.nil?
      response = connection.delete("#{url_for(object)}")
      response.code == '200' or response.code == '204'  # Temporary hack around error in Fedora 3.0 Final's REST API
    end
    
    # Export the given object
    # == Parameters
    # object<String|Object>:: a fedora uri, pid, FedoraObject instance
    # method<Symbol>::        the method to fetch such as :export, :history, :versions, etc
    # extra_params<Hash>::    any other extra parameters to pass to fedora
    #
    def export(object, extra_params={})
      extra_params = {:format=>:foxml, :context=>:archive}.merge!(extra_params)
      if extra_params[:format].kind_of?(String)
        format = extra_params[:format]
      else
        format = case extra_params[:format]
          when :atom then "info:fedora/fedora-system:ATOM-1.1"
          when :atom_zip then "info:fedora/fedora-system:ATOMZip-1.1"
          when :mets then "info:fedora/fedora-system:METSFedoraExt-1.1"
          when :foxml then "info:fedora/fedora-system:FOXML-1.1"
          else "info:fedora/fedora-system:FOXML-1.1"
        end
      end
      fetch_custom(object, "export", :format=>format, :context=>extra_params[:context].to_s)
    end
    
    def ingest(content_to_ingest, extra_params={})
      if extra_params[:pid]
        url = url_for(extra_params[:pid])
      else
        url = url_for("new")
      end
      
      if content_to_ingest.kind_of?(File) 
        content_to_ingest = content_to_ingest.read
      end
        
      connection.post(url,content_to_ingest)
    end

    # Fetch the given object using custom method.  This is used to fetch other aspects of a fedora object,
    # such as profile, versions, etc...
    # == Parameters
    # object<String|Object>:: a fedora uri, pid, FedoraObject instance
    # method<Symbol>::        the method to fetch such as :export, :history, :versions, etc
    # extra_params<Hash>::    any other extra parameters to pass to fedora
    #
    # == Returns
    # This method returns raw xml response from the server
    #-
    def fetch_custom(object, method, extra_params = { :format => 'xml' })
      path = case method
        when :profile then ""
        else "/#{method}"
      end
      
      extra_params.delete(:format) if method == :export
      connection.raw_get("#{url_for(object)}#{path}?#{extra_params.to_fedora_query}").body
    end
    
    def describe_repository
      result_body = connection.raw_get("#{fedora_url.path}/describe?xml=true").body
      XmlSimple.xml_in(result_body)
    end
    
  private
    def convert_xml(response)
      results = FedoraObjects.new
      return results unless response && response['resultList']

      results.session_token = response['listSession']['token'] if response['listSession']
      objectFields = response['resultList']['objectFields']
      case objectFields
        when Array
          objectFields.each { |attrs| results << FedoraObject.new(attrs.rekey!) }
        when Hash
          results << FedoraObject.new(objectFields.rekey!)
      end
      results.each {|result| result.new_object = false}
      results
    end
    
    def url_for(object)
      uri = object.respond_to?(:uri) ? object.uri : object.to_s
      uri = (uri[0..NAMESPACE.length-1] == NAMESPACE ? uri[NAMESPACE.length..-1] : uri) # strip of fedora:info namespace
      "#{fedora_url.path}/objects/#{uri}"
    end
    
    # Low level access to the remote fedora server
    # The +refresh+ parameter toggles whether or not the connection is refreshed at every request
    # or not (defaults to +false+).
    def connection(refresh = false)
      if refresh || @connection.nil?
        @connection = Fedora::Connection.new(@fedora_url, Fedora::XmlFormat, @surrogate)
      end
      @connection
    end
    
    def extract_pid(response)
      CGI.unescape(response['Location'].split('/').last)
    end
  end
end

class FedoraObjects < Array
  attr_accessor :session_token
end

