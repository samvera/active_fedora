module ActiveFedora
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/active_fedora.rake"
    end
    generators do
      puts 'hello'
      require(
        'generators/active_fedora/config/config_generator'
      )
    end
  end
end
