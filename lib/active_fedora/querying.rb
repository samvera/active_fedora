module ActiveFedora
  module Querying
    delegate :find, :first, :where, :limit, :order, :all, :to=>:relation
    def relation
      Relation.new(self)
    end

    # Yields each batch of solr records that was found by the find +options+ as
    # an array. The size of each batch is set by the <tt>:batch_size</tt>
    # option; the default is 1000.
    #
    # Returns a solr result matching the supplied conditions
    # @param[Hash] conditions solr conditions to match
    # @param[Hash] options 
    # @option opts [Array] :sort a list of fields to sort by 
    # @option opts [Array] :rows number of rows to return
    #
    # @example
    #  Person.find_in_batches('age_t'=>'21', {:batch_size=>50}) do |group|
    #  group.each { |person| puts person['name_t'] }
    #  end
    
    def find_in_batches conditions, opts={}
      opts[:q] = create_query(conditions)
      opts[:qt] = solr_query_handler
      #set default sort to created date ascending
      unless opts[:sort].present?
        opts[:sort]=[ActiveFedora::SolrService.solr_name(:system_create,:date)+' asc'] 
      end

      batch_size = opts.delete(:batch_size) || 1000

      counter = 0
      begin
        counter += 1
        response = ActiveFedora::SolrService.instance.conn.paginate counter, batch_size, "select", :params => opts
        docs = response["response"]["docs"]
        yield docs
      end while docs.has_next? 
    end

    # Yields the found ActiveFedora::Base object to the passed block
    #
    # @param [Hash] conditions the conditions for the solr search to match
    # @param [Hash] opts 
    # @option opts [Boolean] :cast when true, examine the model and cast it to the first known cModel
    def find_each( conditions={}, opts={})
      find_in_batches(conditions, opts.merge({:fl=>SOLR_DOCUMENT_ID})) do |group|
        group.each do |hit|
          yield(find_one(hit[SOLR_DOCUMENT_ID], opts[:cast]))
        end
      end
    end


    # Returns true if the pid exists in the repository 
    # @param[String] pid 
    # @return[boolean] 
    def exists?(pid)
      inner = DigitalObject.find_or_initialize(self, pid)
      !inner.new?
    end

    # Get a count of the number of objects from solr
    # Takes :conditions as an argument
    def count(args = {})
      q = search_model_clause ? [search_model_clause] : []
      q << "#{args[:conditions]}"  if args[:conditions]
      SolrService.query(q.join(' AND '), :raw=>true, :rows=>0)['response']['numFound']
    end

    # Returns a solr result matching the supplied conditions
    # @param[Hash,String] conditions can either be specified as a string, or 
    # hash representing the query part of an solr statement. If a hash is 
    # provided, this method will generate conditions based simple equality
    # combined using the boolean AND operator.
    # @param[Hash] options 
    # @option opts [Array] :sort a list of fields to sort by 
    # @option opts [Array] :rows number of rows to return
    def find_with_conditions(conditions, opts={})
      #set default sort to created date ascending
      unless opts.include?(:sort)
        opts[:sort]=[ActiveFedora::SolrService.solr_name(:system_create,:date)+' asc'] 
      end
      SolrService.query(create_query(conditions), opts) 
    end

    def quote_for_solr(value)
      '"' + value.gsub(/(:)/, '\\:').gsub(/(\/)/, '\\/').gsub(/"/, '\\"') + '"'
    end

    # Retrieve the Fedora object with the given pid, explore the returned object, determine its model 
    # using #{ActiveFedora::ContentModel.known_models_for} and cast to that class.
    # Raises a ObjectNotFoundError if the object is not found.
    # @param [String] pid of the object to load
    # @param [Boolean] cast when true, cast the found object to the class of the first known model defined in it's RELS-EXT
    #
    # @example because the object hydra:dataset1 asserts it is a Dataset (hasModel info:fedora/afmodel:Dataset), return a Dataset object (not a Book).
    #   Book.find_one("hydra:dataset1") 
    def find_one(pid, cast=false)
      inner = DigitalObject.find(self, pid)
      af_base = self.allocate.init_with(inner)
      cast ? af_base.adapt_to_cmodel : af_base
    end
    
  
    private 

    # Returns a solr query for the supplied conditions
    # @param[Hash] conditions solr conditions to match
    def create_query(conditions)
      conditions.kind_of?(Hash) ? create_query_from_hash(conditions) : create_query_from_string(conditions)
    end

    def create_query_from_hash(conditions)
      clauses = search_model_clause ?  [search_model_clause] : []
      conditions.each_pair do |key,value|
        unless value.nil?
          if value.is_a? Array
            value.each do |val|
              clauses << "#{key}:#{quote_for_solr(val)}"  
            end
          else
            key = SOLR_DOCUMENT_ID if (key === :id || key === :pid)
            escaped_value = quote_for_solr(value)
            clauses << (key.to_s.eql?(SOLR_DOCUMENT_ID) ? "#{key}:#{escaped_value}" : "#{key}:#{escaped_value}")
          end
        end
      end
      return "*:*" if clauses.empty?
      clauses.compact.join(" AND ")
    end

    def create_query_from_string(conditions)
      model_clause = search_model_clause
      model_clause ? "#{model_clause} AND (#{conditions})" : conditions
    end

    # Return the solr clause that queries for this type of class
    def search_model_clause
      unless self == ActiveFedora::Base
        return ActiveFedora::SolrService.construct_query_for_rel(:has_model, self.to_class_uri)
      end
    end
  end
end
