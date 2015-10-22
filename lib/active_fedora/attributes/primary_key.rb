module ActiveFedora
  module Attributes
    module PrimaryKey
      # If the id is "/foo:1" then to_key ought to return ["foo:1"]
      def to_key
        id && [id]
      end
    end
  end
end
