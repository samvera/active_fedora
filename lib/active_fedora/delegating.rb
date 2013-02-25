module ActiveFedora
  module Delegating
    extend ActiveSupport::Concern

    # Calling inspect may trigger a bunch of loads, but it's mainly for debugging, so no worries.
    def inspect
      values = self.class.delegate_registry.map {|r| "#{r}:#{send(r).inspect}"}
      "#<#{self.class} pid:\"#{pretty_pid}\", #{values.join(', ')}>"
    end

    def [](key)
      array_reader(key)
    end

    def []=(key, value)
      array_setter(key, value)
    end

    private
    def array_reader(field)
      instance_exec(&self.class.delegates[field][:reader])
    end

    def array_setter(field, args)
      instance_exec(args, &self.class.delegates[field][:setter])
    end

    module ClassMethods
      def delegates
        @delegates ||= {}
      end

      def delegates= val
        @delegates = val
      end

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
        create_delegate_reader(field, args)
        create_delegate_setter(field, args)
      end

      def delegate_registry
        self.delegates.keys
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
      #   foo.field2                 # => NoMethodError: undefined method `field2' for #<Foo:0x1af30c>

      def delegate_to(datastream,fields,args={})
        fields.each do |f|
          args.merge!({:to=>datastream})
          create_delegate_reader(f, args)
          create_delegate_setter(f, args)
        end
      end

      private
      def create_delegate_reader(field, args)
        self.delegates[field] ||= {}
        self.delegates[field][:reader] = lambda do
          ds = self.send(args[:to])
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send(field)
          else
            terminology = args[:at] || [field]
            ds.send(:term_values, *terminology)
          end
        end

        define_method field do
          val = self[field]
          args[:unique] ? val.first : val
        end
      end


      def create_delegate_setter(field, args)
        self.delegates[field] ||= {}
        self.delegates[field][:setter] = lambda do |v|
          ds = self.send(args[:to])
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send("#{field}=", v)
          else
            terminology = args[:at] || [field]
            ds.send(:update_indexed_attributes, {terminology => v})
          end
        end
        define_method "#{field}=".to_sym do |v|
          self[field]=v
        end
      end

    end
  end
end
