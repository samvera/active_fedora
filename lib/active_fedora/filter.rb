module ActiveFedora
  module Filter
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Builder
      autoload :Reflection
      autoload :Association
    end
  end
end
