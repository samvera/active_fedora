module ActiveFedora::RDF
  class ValueCaster
    def initialize(value)
      @value = value
    end

    def value
      if @value.respond_to?(:language) # Cast RDF::Literals
        @value.to_s
      else
        @value
      end
    end
  end
end
