module ActiveFedora
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_fedora.rake"
    end

   initializer 'activefedora.autoload', :before => :set_autoload_paths do |app|
     app.config.autoload_paths << 'app/models/datastreams'
    end

    generators do
      require(
        'generators/active_fedora/config/config_generator'
      )
      require(
        'generators/active_fedora/model/model_generator'
      )
    end
  end
end
