require 'rails/generators'

module ActiveFedora
  class Config::SolrGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_fedora_yml
      copy_file('solr.yml', 'config/solr.yml')
    end
  end
end
