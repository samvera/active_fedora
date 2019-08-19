require 'rails/generators'

module ActiveFedora
  class Config::SolrGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    def generate
      # Overwrite the configuration files that Blacklight has installed
      copy_file 'solr.yml', 'config/solr.yml', force: true
      directory 'solr', 'solr', force: true
    end

    def solr_wrapper_config
      # Overwrite the configuration files that Blacklight has installed
      copy_file '.solr_wrapper.yml', force: true
      copy_file 'solr_wrapper_test.yml', 'config/solr_wrapper_test.yml'
    end
  end
end
