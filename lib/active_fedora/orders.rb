module ActiveFedora
  module Orders
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :CollectionProxy
      autoload :ListNode
      autoload :OrderedList
      autoload :TargetProxy
    end
  end
end
