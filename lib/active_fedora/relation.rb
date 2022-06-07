# frozen_string_literal: true
module ActiveFedora
  class Relation
    include Enumerable
    include FinderMethods, Calculations, SpawnMethods, QueryMethods, Delegation

    attr_reader :loaded
    attr_accessor :default_scoped
    alias loaded? loaded

    attr_accessor :values, :klass

    def initialize(klass, _values = {})
      @klass = klass
      @loaded = false
      @values = {}
    end

    # This method gets called on clone
    def initialize_copy(_other)
      # Dup the values
      @values = Hash[@values]
      reset
    end

    # Tries to create a new record with the same scoped attributes
    # defined in the relation. Returns the initialized object if validation fails.
    #
    # Expects arguments in the same format as +Base.create+.
    #
    # ==== Examples
    #   users = User.where(name: 'Oscar')
    #   users.create # #<User id: 3, name: "oscar", ...>
    #
    #   users.create(name: 'fxn')
    #   users.create # #<User id: 4, name: "fxn", ...>
    #
    #   users.create { |user| user.name = 'tenderlove' }
    #   # #<User id: 5, name: "tenderlove", ...>
    #
    #   users.create(name: nil) # validation on name
    #   # #<User id: nil, name: nil, ...>
    def create(*args, &block)
      scoping { @klass.create(*args, &block) }
    end

    def reset
      @first = @loaded = nil
      @records = []
      self
    end

    def to_a
      return @records if loaded?
      args = @klass == ActiveFedora::Base ? { cast: true } : {}
      args[:rows] = limit_value if limit_value
      args[:start] = offset_value if offset_value
      args[:sort] = order_values if order_values

      @records = to_enum(:find_each, where_values, args).to_a
      @loaded = true

      @records
    end

    # Scope all queries to the current scope.
    #
    #   Comment.where(post_id: 1).scoping do
    #     Comment.first
    #   end
    #   # => SELECT "comments".* FROM "comments" WHERE "comments"."post_id" = 1 ORDER BY "comments"."id" ASC LIMIT 1
    #
    # Please check unscoped if you want to remove all previous scopes (including
    # the default_scope) during the execution of a block.
    def scoping
      previous = klass.current_scope
      klass.current_scope = self
      yield
    ensure
      klass.current_scope = previous
    end

    def ==(other)
      case other
      when Relation
        other.where_values == where_values
      when Array
        to_a == other
      end
    end

    delegate :inspect, to: :to_a

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
        to_a.each(&:destroy).tap { reset }.size
      end
    end

    def delete_all(conditions = nil)
      if conditions
        where(conditions).delete_all
      else
        to_a.each(&:delete).tap { reset }.size
      end
    end

    # Returns a hash of where conditions.
    #
    #   User.where(name: 'Oscar').where_values_hash
    #   # => {name: "Oscar"}
    def where_values_hash
      {}
    end

    def scope_for_create
      @scope_for_create ||= where_values_hash.merge(create_with_value)
    end

    def each
      if loaded?
        @records.each { |item| yield item } if block_given?
        @records.to_enum
      else
        find_each(where_values) { |item| yield item } if block_given?
        enum_for(:find_each, where_values)
      end
    end

    def empty?
      !any?
    end

    private

      VALID_FIND_OPTIONS = [:order, :limit, :start, :conditions, :cast].freeze

      def apply_finder_options(options)
        relation = clone
        return relation unless options

        options.assert_valid_keys(VALID_FIND_OPTIONS)
        finders = options.dup
        finders.delete_if { |key, value| value.nil? && key != :limit }

        ([:order, :limit, :start] & finders.keys).each do |finder|
          relation = relation.send(finder, finders[finder])
        end

        relation = relation.where(finders[:conditions]) if options.key?(:conditions)
        relation
      end
  end
end
