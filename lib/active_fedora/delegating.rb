module ActiveFedora
  module Delegating
    extend ActiveSupport::Concern

    # Calling inspect may trigger a bunch of loads, but it's mainly for debugging, so no worries.
    def inspect
      values = self.class.delegates.keys.map {|r| "#{r}:#{send(r).inspect}"}
      "#<#{self.class} pid:\"#{pretty_pid}\", #{values.join(', ')}>"
    end

    def [](key)
      array_reader(key)
    end

    def []=(key, value)
      array_setter(key, value)
    end


    private
    def array_reader(field, *args)
      if args.present?
        instance_exec(*args, &self.class.delegates[field][:reader])
      else
        instance_exec &self.class.delegates[field][:reader]
      end
    end

    def array_setter(field, args)
      instance_exec(args, &self.class.delegates[field][:setter])
    end

    module ClassMethods
      def delegates
        @local_delegates ||= {}.with_indifferent_access
        return @local_delegates unless superclass.respond_to?(:delegates) and value = superclass.delegates
        @local_delegates = value.dup if @local_delegates.empty?
        @local_delegates
      end

      def delegates= val
        @local_delegates = val
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
      #   foo.field2                 # => [""]
      #   foo.field3                 # => NoMethodError: undefined method `field3' for #<Foo:0x1af30c>

      def delegate(*methods)
        fields = methods.dup
        options = fields.pop
        unless options.is_a?(Hash) && to = options[:to]
          raise ArgumentError, "Target is required"
        end
        if ds_specs.has_key? to.to_s 
          create_delegate_reader(fields.first, options)
          create_delegate_setter(fields.first, options)
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
        fields.each do |f|
          args.merge!({:to=>datastream})
          create_delegate_reader(f, args)
          create_delegate_setter(f, args)
        end
      end

      # Reveal if the delegated field is unique or not
      # @param [Symbol] field the field to query
      # @return [Boolean]
      def unique?(field)
        delegates[field][:unique]
      end

      private
      def create_delegate_reader(field, args)
        self.delegates[field] ||= {}
        self.delegates[field][:reader] = lambda do |*opts|
          ds = self.send(args[:to])
          if ds.kind_of?(ActiveFedora::RDFDatastream)
            ds.send(field)
          else
            terminology = args[:at] || [field]
            if terminology.length == 1 && opts.present?
              ds.send(terminology.first, *opts)
            else
              ds.send(:term_values, *terminology)
            end
          end
        end

        self.delegates[field][:unique] = args[:unique]

        define_method field do |*opts|
          val = array_reader(field, *opts)
          self.class.unique?(field) ? val.first : val
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
