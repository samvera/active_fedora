module ActiveFedora
  module Attributes
    module Serializers
      extend ActiveSupport::Concern

      ## This allows you to use date_select helpers in rails views 
      # @param [Hash] parms parameters hash
      # @return [Hash] a parameters list with the date select parameters replaced with dates
      def deserialize_dates_from_form(params)
        dates = {}
        params.each do |key, value| 
          if data = key.to_s.match(/^(.+)\((\d)i\)$/)
            dates[data[1]] ||= {}
            dates[data[1]][data[2]] = value
            params.delete(key)
          end
        end
        dates.each do |key, value|
          params[key] = [value['1'], value['2'], value['3']].join('-')
        end
        params
      end
      
      # set a hash of attributes on the object
      # @param [Hash] params the properties to set on the object
      def attributes=(params)
        super(deserialize_dates_from_form(params))
      end

      module ClassMethods 
        # @param [String] value a string to be cast to integer
        # @param [Hash] options 
        # @option options [Integer] :default a value to return if the passed value argument is blank
        # @return [Integer] 
        def coerce_to_integer(value, options={})
          if value.blank?
            options[:default] || nil
          else
            value.to_i
          end
        end

        # @param [String] value a string to be cast to boolean
        # @param [Hash] options 
        # @option options [Boolean] :default a value to return if the passed value argument is blank
        # @return [Boolean] true if value == "true" or default if value is blank
        def coerce_to_boolean(value, options={})
          if value.blank?
            options[:default] || nil
          else
            value=="true"
          end
        end

        # @param [String] value a string to be cast to boolean
        # @param [Hash] options 
        # @option options [Boolean] :default a value to return if the passed value argument is blank
        # @return [Boolean] true if value == "true" or default if value is blank
        def coerce_to_date(v, options={})
          if v.blank? && options[:default]
            options[:default] == :today ? Date.today : options[:default]
          else
            begin
              Date.parse(v)
            rescue TypeError, ArgumentError
              nil
            end
          end
        end
      end

    end
  end
end
