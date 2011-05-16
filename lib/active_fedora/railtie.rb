require 'active-fedora'
require 'rails'

module ActiveFedora
  class Railtie < Rails::Railtie
    initializer "active-fedora.configure_rails_initialization" do
      ActiveFedora.init
    end
  end
end
