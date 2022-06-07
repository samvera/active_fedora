# frozen_string_literal: true
module ActiveFedora
  module Indexing
    # Utilities for adding fields to index documents
    class Inserter
      # @param [String] field_name_base the field name
      # @param [String] value the value to insert into the index
      # @param [Array<Symbol>] index_as the index type suffixes
      # @param [Hash] solr_doc the index doc to add to
      # @example:
      #   solr_doc = {}
      #   create_and_insert_terms('title', 'War and Peace', [:displayable, :searchable], solr_doc)
      #   solr_doc
      #   # => {"title_ssm"=>["War and Peace"], "title_teim"=>["War and Peace"]}
      def self.create_and_insert_terms(field_name_base, value, index_as, solr_doc)
        index_as.each do |indexer|
          insert_field(solr_doc, field_name_base, value, indexer)
        end
      end

      # @params [Hash] doc the hash to insert the value into
      # @params [String] name the name of the field (without the suffix)
      # @params [String,Date,Array] value the value (or array of values) to be inserted
      # @params [Array,Hash] indexer_args the arguments that find the indexer
      # @returns [Hash] doc the document that was provided with the new field inserted
      def self.insert_field(doc, name, value, *indexer_args)
        # adding defaults indexer
        indexer_args = [:stored_searchable] if indexer_args.empty?
        ActiveFedora.index_field_mapper.solr_names_and_values(name, value, indexer_args).each do |k, v|
          doc[k] ||= []
          if v.is_a? Array
            doc[k] += v
          else
            doc[k] = v
          end
        end
        doc
      end
    end
  end
end
