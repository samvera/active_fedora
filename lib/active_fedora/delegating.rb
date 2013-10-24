module ActiveFedora
  module Delegating
    extend ActiveSupport::Concern
    extend Deprecation
    module ClassMethods
      # Provides a delegate class method to expose methods in metadata streams
      # as member of the base object. Pass the target datastream via the
      # <tt>:to</tt> argument. If you want to return a multivalue result, (e.g. array
      # instead of a string) set the <tt>:multiple</tt> argument to true.
      #
      # The optional <tt>:at</tt> argument provides a terminology that the delegate will point to.
      #
      #   class Foo < ActiveFedora::Base
      #     has_metadata :name => "descMetadata", :type => MyDatastream
      #
      #     delegate :field1, :to=>"descMetadata", multiple: false
      #     delegate :field2, :to=>"descMetadata", :at=>[:term1, :term2], multiple: true
      #   end
      #
      #   foo = Foo.new
      #   foo.field1 = "My Value"
      #   foo.field1                 # => "My Value"
      #   foo.field2                 # => [""]
      #   foo.field3                 # => NoMethodError: undefined method `field3' for #<Foo:0x1af30c>
      #
      #   The optional <tt>:default</tt> forces this method to have the behavior defined by ActiveSupport
      #   until this method has a chance to be removed
      #
      #     delegate :method1, to: 'descMetadata', default: true

      def delegate(*methods)
        fields = methods.dup
        options = fields.pop
        unless options.is_a?(Hash) && to = options[:to]
          raise ArgumentError, "Target is required"
        end
        if ds_specs.has_key?(to.to_s) && !options[:default]
          Deprecation.warn(Delegating, "delegate is deprecated and will be removed in ActiveFedora 7.0. use has_attributes instead", caller(1))
          datastream = options.delete(:to)
          has_attributes fields.first, options.merge!({:datastream=>datastream})
        else
          super(*methods)
        end
      end

      # Allows you to delegate multiple terminologies to the same datastream, instead
      # having to call the method each time for each term.  The target datastream is the
      # first argument, followed by an array of the terms that will point to that
      # datastream.  Terms must be a single value, ie. :field and not [:term1, :term2].
      # This is best accomplished by refining your OM terminology using :ref or :proxy
      # methods to reduce nested terms down to one.
      #
      #   class Foo < ActiveFedora::Base
      #     has_metadata :name => "descMetadata", :type => MyDatastream
      #
      #     delegate_to :descMetadata, [:field1, :field2]
      #   end
      #
      #   foo = Foo.new
      #   foo.field1 = "My Value"
      #   foo.field1                 # => "My Value"
      #   foo.field2                 # => [""]
      #   foo.field3                 # => NoMethodError: undefined method `field3' for #<Foo:0x1af30c>

      def delegate_to(datastream,fields,args={})
        Deprecation.warn(Delegating, "delegate_to is deprecated and will be removed in ActiveFedora 7.0. use has_attributes instead", caller(1))
        has_attributes *fields, args.merge!({:datastream=>datastream})
      end

    end
  end
end
