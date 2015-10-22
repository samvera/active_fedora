module ActiveFedora
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern

      def set_value(*val)
        attribute = val.first
        unless [:has_model, :modified_date].include? attribute
          attribute_will_change!(attribute) unless self[val.first] == val.last
        end
        super
      end
    end
  end
end
