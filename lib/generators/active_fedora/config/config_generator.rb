require 'rails/generators'

module ActiveFedora
  class ConfigGenerator < Rails::Generators::Base
    def generate_configs
      invoke('active_fedora:config:solr')
      invoke('active_fedora:config:fedora')
    end
  end
end
