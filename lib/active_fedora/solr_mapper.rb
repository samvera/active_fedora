require 'active_fedora/solr_service'

module ActiveFedora 
  module SolrMapper
    
    # Generates solr field names from settings in solr_mappings
    def self.solr_name(field_name, field_type)
      name = field_name.to_s + ActiveFedora::SolrService.mappings[field_type.to_s].to_s
      if field_name.kind_of?(Symbol)
        return name.to_sym
      else
        return name.to_s
      end
    end
    
    def solr_name(field_name, field_type)
      ActiveFedora::SolrMapper.solr_name(field_name, field_type)
    end
    
  end
end