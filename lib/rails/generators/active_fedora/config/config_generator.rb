require 'rails/generators'

module ActiveFedora
  class ConfigGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    def create_solr_yml
      template('solr.yml', 'config/solr.yml')
    end

    def create_fedora_yml
      template('fedora.yml', 'config/fedora.yml')
    end
  end
end
