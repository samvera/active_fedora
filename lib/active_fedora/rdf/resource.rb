module ActiveFedora::Rdf
  ##
  # Defines a generic RDF `Resource` as an RDF::Graph with property
  # configuration, accessors, and some other methods for managing
  # resources as discrete subgraphs which can be maintained by a Hydra
  # datastream model.
  #
  # Resources can be instances of ActiveFedora::Rdf::Resource
  # directly, but more often they will be instances of subclasses with
  # registered properties and configuration. e.g.
  #
  #    class License < Resource
  #      configure repository: :default
  #      property :title, predicate: RDF::DC.title, class_name: RDF::Literal do |index|
  #        index.as :displayable, :facetable
  #      end
  #    end
  class Resource < RDF::Graph
    @@type_registry
    extend Configurable
    extend Properties
    extend Deprecation
    include ActiveFedora::Rdf::NestedAttributes
    attr_accessor :parent

    class << self
      def type_registry
        @@type_registry ||= {}
      end

      ##
      # Adapter for a consistent interface for creating a new node from a URI.
      # Similar functionality should exist in all objects which can become a node.
      def from_uri(uri,vals=nil)
        new(uri, vals)
      end
    end

    def writable?
      !frozen?
    end

    ##
    # Initialize an instance of this resource class. Defaults to a
    # blank node subject. In addition to RDF::Graph parameters, you
    # can pass in a URI and/or a parent to build a resource from a
    # existing data.
    #
    # You can pass in only a parent with:
    #    Resource.new(nil, parent)
    #
    # @see RDF::Graph
    def initialize(*args, &block)
      resource_uri = args.shift unless args.first.is_a?(Hash)
      self.parent = args.shift unless args.first.is_a?(Hash)
      set_subject!(resource_uri) if resource_uri
      super(*args, &block)
      reload
      # Append type to graph if necessary.
      self.get_values(:type) << self.class.type if self.class.type.kind_of?(RDF::URI) && type.empty?
    end

    def graph
      Deprecation.warn Resource, "graph is redundant & deprecated. It will be removed in active-fedora 8.0.0.", caller
      self
    end

    def final_parent
      @final_parent ||= begin
        parent = self.parent
        while parent && parent.parent && parent.parent != parent
          parent = parent.parent
        end
        parent
      end
    end

    def attributes=(values)
      raise ArgumentError, "values must be a Hash, you provided #{values.class}" unless values.kind_of? Hash
      values.with_indifferent_access.each do |key, value|
        if self.singleton_class.properties.keys.include?(key)
          set_value(rdf_subject, key, value)
        elsif self.singleton_class.nested_attributes_options.keys.map{ |k| "#{k}_attributes"}.include?(key)
          send("#{key}=".to_sym, value)
        end
      end
    end

    def rdf_subject
      @rdf_subject ||= RDF::Node.new
    end

    def node?
      return true if rdf_subject.kind_of? RDF::Node
      false
    end

    def to_term
      rdf_subject
    end

    def base_uri
      self.class.base_uri
    end

    def type
      self.get_values(:type).to_a.map{|x| x.rdf_subject}
    end

    def type=(type)
      raise "Type must be an RDF::URI" unless type.kind_of? RDF::URI
      self.update(RDF::Statement.new(rdf_subject, RDF.type, type))
    end

    ##
    # Look for labels in various default fields, prioritizing
    # configured label fields
    def rdf_label
      labels = Array(self.class.rdf_label)
      labels += default_labels
      labels.each do |label|
        values = get_values(label)
        return values unless values.empty?
      end
      node? ? [] : [rdf_subject.to_s]
    end

    def fields
      properties.keys.map(&:to_sym).reject{|x| x == :type}
    end

    ##
    # Load data from URI
    def fetch
      load(rdf_subject)
      self
    end

    def persist!
      raise "failed when trying to persist to non-existant repository or parent resource" unless repository
      repository.delete [rdf_subject,nil,nil] unless node?
      if node?
        repository.statements.each do |statement|
          repository.send(:delete_statement, statement) if statement.subject == rdf_subject
        end
      end
      repository << self
      @persisted = true
    end

    def persisted?
      @persisted ||= false
      return (@persisted and parent.persisted?) if parent
      @persisted
    end

    ##
    # Repopulates the graph from the repository or parent resource.
    def reload
      @term_cache ||= {}
      if self.class.repository == :parent
        return false if final_parent.nil?
      end
      self << repository.query(subject: rdf_subject)
      unless empty?
        @persisted = true
      end
      true
    end

    ##
    # Adds or updates a property with supplied values.
    #
    # Handles two argument patterns. The recommended pattern is:
    #    set_value(property, values)
    #
    # For backwards compatibility, there is support for explicitly
    # passing the rdf_subject to be used in the statement:
    #    set_value(uri, property, values)
    #
    # @note This method will delete existing statements with the correct subject and predicate from the graph
    def set_value(*args)
      # Add support for legacy 3-parameter syntax
      if args.length > 3 || args.length < 2
        raise ArgumentError("wrong number of arguments (#{args.length} for 2-3)")
      end
      values = args.pop
      get_term(args).set(values)
    end

    ##
    # Returns an array of values belonging to the property
    # requested. Elements in the array may RdfResource objects or a
    # valid datatype.
    #
    # Handles two argument patterns. The recommended pattern is:
    #    get_values(property)
    #
    # For backwards compatibility, there is support for explicitly
    # passing the rdf_subject to be used in th statement:
    #    get_values(uri, property)
    def get_values(*args)
      get_term(args)
    end

    def get_term(args)
      @term_cache ||= {}
      term = ActiveFedora::Rdf::Term.new(self, args)
      @term_cache["#{term.rdf_subject}/#{term.property}"] ||= term
      @term_cache["#{term.rdf_subject}/#{term.property}"]
    end

    ##
    # Set a new rdf_subject for the resource.
    #
    # This raises an error if the current subject is not a blank node,
    # and returns false if it can't figure out how to make a URI from
    # the param. Otherwise it creates a URI for the resource and
    # rebuilds the graph with the updated URI.
    #
    # Will try to build a uri as an extension of the class's base_uri
    # if appropriate.
    #
    # @param [#to_uri, #to_s] uri_or_str the uri or string to use
    def set_subject!(uri_or_str)
      raise "Refusing update URI when one is already assigned!" unless node?
      # Refusing set uri to an empty string.
      return false if uri_or_str.nil? or uri_or_str.to_s.empty?
      # raise "Refusing update URI! This object is persisted to a datastream." if persisted?
      old_subject = rdf_subject
      @rdf_subject = get_uri(uri_or_str)

      each_statement do |statement|
        if statement.subject == old_subject
          delete(statement)
          self << RDF::Statement.new(rdf_subject, statement.predicate, statement.object)
        elsif statement.object == old_subject
          delete(statement)
          self << RDF::Statement.new(statement.subject, statement.predicate, rdf_subject)
        end
      end
    end

    def destroy
      clear
      persist!
      parent.destroy_child(self)
    end

    def destroy_child(child)
      statements.each do |statement|
        delete_statement(statement) if statement.subject == child.rdf_subject || statement.object == child.rdf_subject
      end
    end

    def new_record?
      not persisted?
    end

    ##
    # @return [String] the string to index in solr
    def solrize
      node? ? rdf_label : rdf_subject.to_s
    end

    def mark_for_destruction
      @marked_for_destruction = true
    end

    def marked_for_destruction?
      @marked_for_destruction
    end

    private

    def properties
      self.singleton_class.properties
    end

    def property_for_predicate(predicate)
      properties.each do |property, values|
        return property if values[:predicate] == predicate
      end
      return nil
    end

    def default_labels
      [RDF::SKOS.prefLabel,
       RDF::DC.title,
       RDF::RDFS.label,
       RDF::SKOS.altLabel,
       RDF::SKOS.hiddenLabel]
    end

    ##
    # Return the repository (or parent) that this resource should
    # write to when persisting.
    def repository
      @repository ||= 
        if self.class.repository == :parent
          final_parent
        else
          ActiveFedora::Rdf::Repositories.repositories[self.class.repository]
        end
    end

    private

      ##
      # Takes a URI or String and aggressively tries to create a valid RDF URI.
      # Combines the input with base_uri if appropriate.
      #
      # @TODO: URI.scheme_list is naive and incomplete. Find a better way to check for an existing scheme.
      def get_uri(uri_or_str)
        return uri_or_str.to_uri if uri_or_str.respond_to? :to_uri
        return uri_or_str if uri_or_str.kind_of? RDF::Node
        uri_or_str = uri_or_str.to_s
        return RDF::Node(uri_or_str[2..-1]) if uri_or_str.start_with? '_:'
        return RDF::URI(uri_or_str) if RDF::URI(uri_or_str).valid? and (URI.scheme_list.include?(RDF::URI.new(uri_or_str).scheme.upcase) or RDF::URI.new(uri_or_str).scheme == 'info')
        return RDF::URI(self.base_uri.to_s + (self.base_uri.to_s[-1,1] =~ /(\/|#)/ ? '' : '/') + uri_or_str) if base_uri && !uri_or_str.start_with?(base_uri.to_s)
        raise RuntimeError "could not make a valid RDF::URI from #{uri_or_str}"
      end
  end
end
