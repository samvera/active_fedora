require 'rails/generators'

module ActiveFedora
  class Config::FedoraGenerator < Rails::Generators::Base
    source_root ::File.expand_path('../templates', __FILE__)

    def generate
      copy_file('fedora.yml', 'config/fedora.yml')
    end

    def fcrepo_wrapper_config
      copy_file '.fcrepo_wrapper', '.fcrepo_wrapper'
      copy_file 'fcrepo_wrapper_test.yml', 'config/fcrepo_wrapper_test.yml'
    end
  end
end
