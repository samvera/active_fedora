# frozen_string_literal: true
module ActiveFedora
  class Railtie < Rails::Railtie
    config.app_middleware.insert_after ::ActionDispatch::Callbacks,
                                       ActiveFedora::LdpCache
    config.action_dispatch.rescue_responses["ActiveFedora::ObjectNotFoundError"] = :not_found

    config.eager_load_namespaces << ActiveFedora

    initializer 'active_fedora.autoload', before: :set_autoload_paths do |app|
      app.config.autoload_paths << 'app/models/datastreams'
    end

    initializer "active_fedora.logger" do
      ActiveSupport.on_load(:active_fedora) do
        self.logger = ::Rails.logger if logger.is_a? NullLogger
      end
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
