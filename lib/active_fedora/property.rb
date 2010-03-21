module ActiveFedora
  class Property
    
    attr_accessor :name, :instance_variable_name
    
    def initialize(model, name, type, options = {})
      @name = name
      @instance_variable_name = "@#{@name}"
    end
    
    def field
    end
    
  end
end