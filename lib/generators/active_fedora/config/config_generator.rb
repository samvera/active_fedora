require 'rails/generators'

module ActiveFedora
  class ConfigGenerator < Rails::Generators::Base
    def generate_configs
      generate('active_fedora:config:fedora')
      generate('active_fedora:config:solr')
    end
  end
end
