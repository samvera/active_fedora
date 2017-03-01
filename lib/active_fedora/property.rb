module ActiveFedora
  class Property
    attr_accessor :name, :instance_variable_name

    def initialize(_model, name, _type, _options = {})
      @name = name
      @instance_variable_name = "@#{@name}"
    end

    def field; end
  end
end
