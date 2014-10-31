require 'rails/generators'

module ActiveFedora
  class Config::SolrGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    def generate
      # Overwrite the configuration files that Blacklight has installed
      copy_file 'jetty.yml', 'config/jetty.yml', force: true
      copy_file 'solr.yml', 'config/solr.yml', force: true
      directory 'solr_conf', 'solr_conf'
    end
  end
end
