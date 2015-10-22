module ActiveFedora
  module Attributes
    module Serializers
      ## This allows you to use date_select helpers in rails views
      # @param [Hash] params parameters hash
      # @return [Hash] a parameters list with the date select parameters replaced with dates
      def deserialize_dates_from_form(params)
        dates = {}
        params.each do |key, value|
          next unless data = key.to_s.match(/^(.+)\((\d)i\)$/)
          dates[data[1]] ||= {}
          dates[data[1]][data[2]] = value
          params.delete(key)
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
    end
  end
end
