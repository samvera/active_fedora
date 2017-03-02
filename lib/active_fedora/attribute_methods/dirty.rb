module ActiveFedora
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern

      def dirty_attribute(attribute, values)
        unless [:has_model, :modified_date].include? attribute
          attribute_will_change!(attribute) unless Array(self[attribute]).to_set == Array(values).to_set
        end
      end
    end
  end
end
