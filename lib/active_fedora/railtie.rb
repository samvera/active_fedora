module ActiveFedora
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_fedora.rake"
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
