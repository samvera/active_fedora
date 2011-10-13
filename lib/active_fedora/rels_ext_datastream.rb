require 'active_support/core_ext/class/inheritable_attributes'
require 'solrizer/field_name_mapper'
require 'uri'
require 'rdf/rdfxml'
require 'rdf'

module ActiveFedora
  class RelsExtDatastream < Datastream
    
    include Solrizer::FieldNameMapper
    attr_accessor :model
    
    
    def changed?
      (model && model.relationships_are_dirty) || super
    end

    def serialize!
      self.content = to_rels_ext(self.pid) if model.relationships_are_dirty
      model.relationships_are_dirty = false
    end
    

    def to_xml(fields_xml) 
      to_rels_ext(self.pid) 
    end
      
    # Populate a RelsExtDatastream object based on the "datastream" content 
    # Assumes that the datastream contains RDF XML from a Fedora RELS-EXT datastream 
    # @param [ActiveFedora::MetadataDatastream] tmpl the Datastream object that you are populating
    # @param [String] the "rdf" node 
    def self.from_xml(xml, tmpl) 
      if (xml.nil?)
        ### maybe put the template here?
      else
        RDF::RDFXML::Reader.new(xml) do |reader|
          reader.each_statement do |statement|
            literal = statement.object.kind_of?(RDF::Literal)
            predicate = statement.predicate.to_str.gsub(/^[^#]+#/, '').underscore.to_sym
            object = literal ? statement.object.value : statement.object.to_str
            tmpl.model.add_relationship(predicate, object)
          end
        end
        tmpl.model.relationships_are_dirty = false
        tmpl
      end
    end

    # Creates a RELS-EXT datastream for insertion into a Fedora Object
    # @param [String] pid
    # @param [Hash] relationships (optional) @default self.relationships
    # Note: This method is implemented on SemanticNode instead of RelsExtDatastream because SemanticNode contains the relationships array
    def to_rels_ext(pid, relationships=self.model.relationships)
      vocabularies = {"info:fedora/fedora-system:def/relations-external#" =>  RDF::Vocabulary.new("info:fedora/fedora-system:def/relations-external#"),
        "info:fedora/fedora-system:def/model#" =>  RDF::Vocabulary.new("info:fedora/fedora-system:def/model#")}
                  
      graph = RDF::Graph.new
      subject =  RDF::URI.new("info:fedora/#{pid}")
      self.model.outbound_relationships.each do |predicate, targets_array|
        xmlns=String.new
        case predicate
        when :has_model, "hasModel", :hasModel
          xmlns="info:fedora/fedora-system:def/model#"
          begin
            rel_predicate = ActiveFedora::Base.predicate_lookup(predicate,xmlns)
          rescue UnregisteredPredicateError
            xmlns = nil
            rel_predicate = nil
          end
        else
          xmlns="info:fedora/fedora-system:def/relations-external#"
          begin
            rel_predicate = ActiveFedora::Base.predicate_lookup(predicate,xmlns)
          rescue UnregisteredPredicateError
            xmlns = nil
            rel_predicate = nil
          end
        end
        
        unless xmlns && rel_predicate
          rel_predicate, xmlns = ActiveFedora::Base.find_predicate(predicate)
        end
        graph_predicate = vocabularies[xmlns][rel_predicate] 
        targets_array.each do |target|
          literal = URI.parse(target).scheme.nil?
          object = literal ? RDF::Literal.new(target) : RDF::URI.new(target)
          stm = RDF::Statement.new(subject, graph_predicate, object)
          graph.insert stm
        end
      end

      xml = RDF::RDFXML::Writer.buffer do |writer|
        graph.each_statement do |statement|
          writer << statement
        end
      end

      xml

    end

    
    # Serialize the datastream's RDF relationships to solr
    # @param [Hash] solr_doc @deafult an empty Hash
    def to_solr(solr_doc = Hash.new)
      self.model.relationships.each_pair do |subject, predicates|
        if subject == :self || subject == "info:fedora/#{self.pid}"
          predicates.each_pair do |predicate, values|
            values.each do |val|
              ::Solrizer::Extractor.insert_solr_field_value(solr_doc, solr_name(predicate, :symbol), val )
            end
          end
        end
      end
      return solr_doc
    end
    
    # ** EXPERIMENTAL **
    # 
    # This is utilized by ActiveFedora::Base.load_instance_from_solr to load 
    # the relationships hash using the Solr document passed in instead of from the RELS-EXT datastream
    # in Fedora.  Utilizes solr_name method (provided by Solrizer::FieldNameMapper) to map solr key to
    # relationship predicate. 
    #
    # ====Warning
    #  Solr must be synchronized with RELS-EXT data in Fedora.
    def from_solr(solr_doc)
      #cycle through all possible predicates
      ActiveFedora::Base.predicate_mappings[ActiveFedora::Base.default_predicate_namespace].keys.each do |predicate|
        predicate_symbol = ActiveFedora::SolrService.solr_name(predicate, :symbol)
        value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol]) 
        unless value.nil? 
          if value.is_a? Array
            value.each do |obj|
              #o_uri = URI.parse(obj)
              #literal = o_uri.scheme.nil?
              #r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>obj, :is_literal=>literal)
              model.add_relationship(predicate, obj)
            end
          else
            #o_uri = URI.parse(value)
            #literal = o_uri.scheme.nil?
            #r = ActiveFedora::Relationship.new(:subject=>:self, :predicate=>predicate, :object=>value, :is_literal=>literal)
            model.add_relationship(predicate, value)
          end
        end
      end
      @load_from_solr = true
    end
  end
end
