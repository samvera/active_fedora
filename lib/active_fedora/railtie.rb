module ActiveFedora
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_fedora.rake"
    end

   initializer 'active_fedora.autoload', :before => :set_autoload_paths do |app|
     app.config.autoload_paths << 'app/models/datastreams'
    end

   initializer "active_fedora.logger" do
      ActiveSupport.on_load(:active_fedora) { self.logger ||= ::Rails.logger }
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
