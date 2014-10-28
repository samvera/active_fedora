module ActiveFedora
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern

      def set_value(*val)
        attribute = val.first
        unless [:has_model, :modified_date, :ldp_contains, :ldp_member].include? attribute
          attribute_will_change!(attribute)
        end
        super
      end
    end
  end
end

