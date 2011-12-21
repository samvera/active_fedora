require 'uri'
module ActiveFedora
  
  class Relationship 
    
    attr_accessor :subject, :predicate, :object, :is_literal, :data_type
    def initialize(attr={})
      ActiveSupport::Deprecation.warn("ActiveFedora::Releationship is deprecated and will be removed in the next release")
      attr = {:is_literal => false}.merge(attr)
      @is_literal = attr[:is_literal] # must happen first
      self.subject = attr[:subject]
      @predicate = attr[:predicate]
      self.object = attr[:object]
      @data_type = attr[:data_type]
    end
    
    def subject=(subject)
      @subject = generate_uri(subject)
    end
    
    def subject_pid=(pid)
      @subject = "info:fedora/#{pid}"
    end
    
    def object=(object)
      @object = (is_literal)? object : generate_uri(object)
    end
    
    def object_pid=(pid)
      @object = "info:fedora/#{pid}"
    end
    
    def generate_uri(input)
      if input.class == Symbol || input == nil
        return input
      elsif input.is_a? URI::Generic
        return input.to_s
      elsif input.respond_to?(:pid)
        return "info:fedora/#{input.pid}"
      else
        input.include?("info:fedora") ? input : "info:fedora/#{input}"
      end
    end
  
  end
  
end
