module ActiveFedora
  
  class Relationship 
    
    attr_accessor :subject, :predicate, :object, :is_literal, :data_type
    def initialize(attr={})
      attr.merge!({:is_literal => false})
      self.subject = attr[:subject]
      @predicate = attr[:predicate]
      self.object = attr[:object]
      @is_literal = attr[:is_literal]
      @data_type = attr[:data_type]
    end
    
    def subject=(subject)
      @subject = generate_uri(subject)
    end
    
    def subject_pid=(pid)
      @subject = "info:fedora/#{pid}"
    end
    
    def object=(object)
      @object = generate_uri(object)
    end
    
    def object_pid=(pid)
      @object = "info:fedora/#{pid}"
    end
    
    def generate_uri(input)
      if input.class == Symbol || input == nil
        return input
      elsif input.respond_to?(:pid)
        return "info:fedora/#{input.pid}"
      else
        input.include?("info:fedora") ? input : "info:fedora/#{input}"
      end
    end
  
  end
  
end