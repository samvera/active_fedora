module ActiveFedora
  class Relation
    extend Deprecation
    delegate :map, :each, :collect, :all?, :include?, :to => :to_a

    attr_reader :loaded
    alias :loaded? :loaded

    attr_accessor :limit_value, :where_values, :order_values
    
    def initialize(klass)
      @klass = klass
      @loaded = false
      self.where_values = []
      self.order_values = []
    end

    def reset
      @first = @loaded = nil
      @records = []
      self
    end


    # Returns the first records that was found.
    #
    # @example
    #  Person.where(name_t: 'Jones').first
    #    => #<Person @id="foo:123" @name='Jones' ... >
    def first
      if loaded?
        @records.first
      else
        @first ||= limit(1).to_a[0]
      end
    end

    # Returns the last record sorted by id.  ID was chosen because this mimics
    # how ActiveRecord would achieve the same behavior.
    #
    # @example
    #  Person.where(name_t: 'Jones').last
    #    => #<Person @id="foo:123" @name='Jones' ... >
    def last
      if loaded?
        @records.last
      else
        @last ||= order('id desc').limit(1).to_a[0]
      end
    end

    # Limits the number of returned records to the value specified
    #
    # @option [Integer] value the number of records to return
    #
    # @example
    #  Person.where(name_t: 'Jones').limit(10)
    #    => [#<Person @id="foo:123" @name='Jones'>, #<Person @id="foo:125" @name='Jones'>, ...]
    def limit(value)
      relation = clone
      relation.limit_value = value
      relation
    end

    # Limits the returned records to those that match the provided search conditions
    #
    # @option [Hash] opts a hash of solr conditions
    #
    # @example
    #  Person.where(name_t: 'Mario', occupation_s: 'Plumber')
    #    => [#<Person @id="foo:123" @name='Mario'>, #<Person @id="foo:125" @name='Mario'>, ...]
    def where(opts)
      return self if opts.blank?
      relation = clone
      relation.where_values = opts
      relation
    end

    # Order the returned records by the field and direction provided
    #
    # @option [Array<String>] args a list of fields and directions to sort by 
    #
    # @example
    #  Person.where(occupation_s: 'Plumber').order('name_t desc', 'color_t asc')
    #    => [#<Person @id="foo:123" @name='Luigi'>, #<Person @id="foo:125" @name='Mario'>, ...]
    def order(*args)
      return self if args.blank?

      relation = clone
      relation.order_values += args.flatten
      relation
    end

    extend Deprecation
    self.deprecation_horizon = 'active-fedora 7.0.0'

    # Returns an Array of objects of the Class that +find+ is being 
    # called on
    #
    # @param[String,Symbol,Hash] args either a pid or :all or a hash of conditions
    # @option args [Integer] :rows when :all is passed, the maximum number of rows to load from solr
    # @option args [Boolean] :cast when true, examine the model and cast it to the first known cModel
    def find(*args)
      return to_a.find { |*block_args| yield(*block_args) } if block_given?
      options = args.extract_options!

      # TODO is there any reason not to cast?
      if !options.has_key?(:cast)
        Deprecation.warn(Relation, "find's cast option will default to true", caller)
      end
      cast = options.delete(:cast)
      if options[:sort]
        # Deprecate sort sometime?
        sort = options.delete(:sort) 
        options[:order] ||= sort if sort.present?
      end

      if options.present?
        options = args.first unless args.empty?
        options = {conditions: options}
        apply_finder_options(options).all
      else
        case args.first
        when :first, :last, :all
          Deprecation.warn Relation, "ActiveFedora::Base.find(#{args.first.inspect}) is deprecated.  Use ActiveFedora::Base.#{args.first} instead. This option will be removed in ActiveFedora 7", caller
          send(args.first)
        else
          find_with_ids(args, cast)
        end
      end
    end

    def find_with_ids(ids, cast)
      expects_array = ids.first.kind_of?(Array)
      return ids.first if expects_array && ids.first.empty?

      ids = ids.flatten.compact.uniq

      case ids.size
      when 0
        raise ArgumentError, "Couldn't find #{@klass.name} without an ID"
      when 1
        result = @klass.find_one(ids.first, cast)
        expects_array ? [ result ] : result
      else
        find_some(ids, cast)
      end
    end

    def find_some(ids, cast)
      ids.map{|id| @klass.find_one(id, cast)}
    end

    # A convenience wrapper for <tt>find(:all, *args)</tt>. You can pass in all the
    # same arguments to this method as you can to <tt>find(:all)</tt>.
    def all(*args)
      args.any? ? apply_finder_options(args.first).to_a : to_a
    end



    def to_a
      return @records if loaded?
      args = {} #:cast=>true}
      args[:rows] = @limit_value if @limit_value
      args[:sort] = @order_values if @order_values
      
      query = @where_values.present? ? @where_values : {}
      @records = @klass.to_enum(:find_each, query, args).to_a

      @records
    end

    # Get a count of the number of objects from solr
    # Takes :conditions as an argument
    def count(*args)
      return apply_finder_options(args.first).count  if args.any?
      opts = {}
      opts[:rows] = @limit_value if @limit_value
      opts[:sort] = @order_values if @order_values
      
      query = @where_values.present? ? @where_values : {}
      @klass.calculate :count, query, opts

    end



    def ==(other)
      case other
      when Relation
        other.where_values == where_values
      when Array
        to_a == other
      end
    end

    def inspect
      to_a.inspect
    end

    # Destroys the records matching +conditions+ by instantiating each
    # record and calling its +destroy+ method. Each object's callbacks are
    # executed (including <tt>:dependent</tt> association options and
    # +before_destroy+/+after_destroy+ Observer methods). Returns the
    # collection of objects that were destroyed; each will be frozen, to
    # reflect that no changes should be made (since they can't be
    # persisted).
    #
    # Note: Instantiation, callback execution, and deletion of each
    # record can be time consuming when you're removing many records at
    # once. It generates at least one fedora +DELETE+ query per record (or
    # possibly more, to enforce your callbacks). If you want to delete many
    # rows quickly, without concern for their associations or callbacks, use
    # +delete_all+ instead.
    #
    # ==== Parameters
    #
    # * +conditions+ - A string, array, or hash that specifies which records
    #   to destroy. If omitted, all records are destroyed. See the
    #   Conditions section in the ActiveFedora::Relation#where for
    #   more information.
    #
    # ==== Examples
    #
    #   Person.destroy_all(:status_s => "inactive")
    #   Person.where(:age_i => 18).destroy_all
    def destroy_all(conditions = nil)
      if conditions
        where(conditions).destroy_all
      else
        to_a.each {|object| object.destroy }.tap { reset }.size
      end
    end

    def delete_all(conditions = nil)
      if conditions
        where(conditions).delete_all
      else
        to_a.each {|object| object.delete }.tap { reset }.size
      end
    end


    private

    VALID_FIND_OPTIONS = [:order, :limit, :conditions, :cast]
    
    def apply_finder_options(options)
      relation = clone
      return relation unless options

      options.assert_valid_keys(VALID_FIND_OPTIONS)
      finders = options.dup
      finders.delete_if { |key, value| value.nil? && key != :limit }

      ([:order,:limit] & finders.keys).each do |finder|
        relation = relation.send(finder, finders[finder])
      end

      relation = relation.where(finders[:conditions]) if options.has_key?(:conditions)
      relation
    end
    
  end
end
