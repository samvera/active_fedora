require 'rails/generators'

module ActiveFedora
  class Config::SolrGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def generate
      copy_file('solr.yml', 'config/solr.yml')
      directory('solr_conf', 'solr_conf')
    end
  end
end
