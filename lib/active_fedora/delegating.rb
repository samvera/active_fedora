module ActiveFedora
  module Delegating
    
    def delegate(field, args ={})
      create_delegate_accessor(field, args)
      create_delegate_setter(field, args)
    end

    def create_delegate_accessor(field, args)
        define_method field do
          ds = self.send(args[:to])
          if ds.kind_of? ActiveFedora::NokogiriDatastream 
            ds.send(:term_values, field).first
          else 
            ds.send(:get_values, field).first
          end 
        end
    end

    def create_delegate_setter(field, args)
        define_method "#{field}=".to_sym do |v|
          ds = self.send(args[:to])
          if ds.kind_of? ActiveFedora::NokogiriDatastream 
            ds.send(:update_indexed_attributes, {[field] => v})
          else 
            ds.send(:set_value, field, v)
          end
        end
    end

  end
end
