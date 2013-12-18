require 'rails/generators'

module ActiveFedora
  class ConfigGenerator < Rails::Generators::Base
    def generate_configs
      generate('active_fedora:config:solr')
      generate('active_fedora:config:fedora')
    end
  end
end
