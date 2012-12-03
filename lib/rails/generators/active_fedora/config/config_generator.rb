require 'rails/generators'

module ActiveFedora
  class ConfigGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    def create_configuration_files
      copy_file('solr.yml', 'config/solr.yml')
      copy_file('fedora.yml', 'config/fedora.yml')
    end
  end
end
