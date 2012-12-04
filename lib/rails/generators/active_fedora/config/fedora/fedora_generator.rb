require 'rails/generators'

module ActiveFedora
  module Config
    class FedoraGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def copy_fedora_yml
        copy_file('fedora.yml', 'config/fedora.yml')
      end
    end
  end
end
