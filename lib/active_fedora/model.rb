require 'active_fedora/fedora_object'

SOLR_DOCUMENT_ID = "id" unless defined?(SOLR_DOCUMENT_ID)

module ActiveFedora
  # = ActiveFedora
  # This module mixes various methods into the including class,
  # much in the way ActiveRecord does.  
  module Model 
    extend ActiveFedora::FedoraObject

    attr_accessor :properties

    def self.included(klass) # :nodoc:
      klass.extend(ClassMethods)
    end

    def add_metadata
    end

    def datastream
    end


    #
    # =Class Methods
    # These methods are mixed into the inheriting class.
    #
    # Accessor and mutator methods are dynamically generated based 
    # on the contents of the @@field_spec hash, which stores the 
    # field specifications recorded during invocation of has_metadata.
    #
    # Each metadata field will generate 3 methods:
    #
    #   fieldname_values
    #     *returns the current values array for this field
    #   fieldname_values=(val) 
    #     *store val as the values array. val 
    #     may be a single string, or an array of strings 
    #     (single items become single element arrays).
    #   fieldname_append(val)
    #     *appends val to the values array.
    module ClassMethods

      # Load an instance with the following pid. Note that you can actually
      # pass an pid into this method, regardless of Fedora model type, and
      # ActiveFedora will try to parse the results into the current type
      # of self, which may or may not be what you want.
      def load_instance(pid)
        Fedora::Repository.instance.find_model(pid, self)
      end

      # Takes :all or a pid as arguments
      # Returns an Array of objects of the Class that +find+ is being 
      # called on
      def find(args)
        if args == :all
          escaped_class_name = self.name.gsub(/(:)/, '\\:')
          q = "#{solr_name(:active_fedora_model, :symbol)}:#{escaped_class_name}"
        elsif args.class == String
          escaped_id = args.gsub(/(:)/, '\\:')
          q = "#{SOLR_DOCUMENT_ID}:#{escaped_id}"
        end
        hits = SolrService.instance.conn.query(q).hits 
        results = hits.map do |hit|
          obj = Fedora::Repository.instance.find_model(hit[SOLR_DOCUMENT_ID], self)
          #obj.inner_object.new_object = false
          #return obj
        end
        results.first
      end

      #Sends a query directly to SolrService
      def solr_search(query, args={})
        SolrService.instance.conn.query(query, args)
      end


      #  If query is :all, this method will query Solr for all instances
      #  of self.type (based on active_fedora_model_s as indexed
      #  by Solr). If the query is any other string, this method simply does
      #  a pid based search (id:query). 
      #
      #  Note that this method does _not_ return ActiveFedora::Model 
      #  objects, but rather an array of SolrResults.
      #
      #  Args is an options hash, which is passed into the SolrService 
      #  connection instance.
      def find_by_solr(query, args={})
        if query == :all
          escaped_class_name = self.name.gsub(/(:)/, '\\:')
          SolrService.instance.conn.query("#{solr_name(:active_fedora_model, :symbol)}:#{escaped_class_name}", args)
        elsif query.class == String
          escaped_id = query.gsub(/(:)/, '\\:')          
          SolrService.instance.conn.query("#{SOLR_DOCUMENT_ID}:#{escaped_id}", args)
        end
      end


      #wrapper around instance_variable_set, sets @name to value
      def attribute_set(name, value)
        instance_variable_set("@#{name}", value)
      end

      #wrapper around instance_variable_get, returns current value of @name
      def attribute_get(name)
        #instance_variable_get(properties[":#{name}"].instance_variable_name)
        instance_variable_get("@#{name}")
      end

    end
    def create_property_getter(property) # :nodoc:

      class_eval <<-END
          def #{property.name}
            attribute_get("#{property.name}")
          end
          END
    end

    def create_property_setter(property)# :nodoc:
      class_eval <<-END
          def #{property.name}=(value)
            attribute_set("#{property.name}", value)
          end
          END
    end

  end
end
