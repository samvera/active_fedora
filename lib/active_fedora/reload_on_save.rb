module ActiveFedora #:nodoc:
  # = Active Fedora Reload On Save
  module ReloadOnSave

    attr_writer :reload_on_save

    def reload_on_save?
      !!@reload_on_save
    end

    def refresh
      self.reload if reload_on_save?
    end
  end
end

