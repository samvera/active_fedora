module ActiveFedora
  module Delegating
    extend ActiveSupport::Concern

    module ClassMethods
      # Provides a delegate class method to expose methods in metadata streams
      # as member of the base object. Pass the target datastream via the 
      # <tt>:to</tt> argument. If you want to return a unique result, (e.g. string 
      # instead of an array) set the <tt>:unique</tt> argument to true.
      #
      # The optional <tt>:at</tt> argument provides a terminology that the delegate will point to.
      #   
      #   class Foo < ActiveFedora::Base
      #     has_metadata :name => "descMetadata", :type => MyDatastream 
      #     
      #     delegate :field1, :to=>"descMetadata", :unique=>true
      #     delegate :field2, :to=>"descMetadata", :at=>[:term1, :term2]
      #   end
      #
      #   foo = Foo.new
      #   foo.field1 = "My Value"
      #   foo.field1                 # => "My Value"
      #   foo.field2                 # => NoMethodError: undefined method `field2' for #<Foo:0x1af30c>

      def delegate(field, args ={})
        create_delegate_accessor(field, args)
        create_delegate_setter(field, args)
      end

      private
        def create_delegate_accessor(field, args)
            define_method field do
              ds = self.send(args[:to])
              val = if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::DCRDFDatastream)
                ds.send(:get_values, field)
              else 
                terminology = args[:at] || [field]
                ds.send(:term_values, *terminology)
              end 
              args[:unique] ? val.first : val
                
            end
        end

        def create_delegate_setter(field, args)
            define_method "#{field}=".to_sym do |v|
              ds = self.send(args[:to])
              if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::DCRDFDatastream)
                ds.send(:set_value, field, v)
              else 
                terminology = args[:at] || [field]
                ds.send(:update_indexed_attributes, {terminology => v})
              end
            end
        end
    end
  end
end
