module ActiveFedora
  module Associations
    class CollectionAssociation < Association #:nodoc:
      attr_reader :proxy

      def initialize(owner, reflection)
        super
        construct_query
      end

      # Implements the reader method, e.g. foo.items for Foo.has_many :items
      # @param opts [Boolean, Hash] if true, force a reload
      # @option opts [Symbol] :response_format can be ':solr' to return a solr result.
      def reader(opts = false)
        if opts.kind_of?(Hash)
          if opts.delete(:response_format) == :solr
            return load_from_solr(opts)
          end
          raise ArgumentError, "Hash parameter must include :response_format=>:solr (#{opts.inspect})"
        else
          force_reload = opts
        end
        reload if force_reload || stale_target?
        @proxy ||= CollectionProxy.new(self)
      end

      # Implements the writer method, e.g. foo.items= for Foo.has_many :items
      def writer(records)
        replace(records)
      end

      # Implements the ids reader method, e.g. foo.item_ids for Foo.has_many :items
      def ids_reader
        if loaded?
          load_target.map do |record|
            record.id
          end
        else
          load_from_solr.map do |solr_record|
            solr_record['id']
          end
        end
      end

      # Implements the ids writer method, e.g. foo.item_ids= for Foo.has_many :items
      def ids_writer(ids)
        ids = Array(ids).reject { |id| id.blank? }
        replace(klass.find(ids))#.index_by { |r| r.id }.values_at(*ids))
        #TODO, like this when find() can return multiple records
        #send("#{reflection.name}=", reflection.klass.find(ids))
        #send("#{reflection.name}=", ids.collect { |id| reflection.klass.find(id)})
      end

      def reset
        reset_target!
        @loaded = false
      end

      def find(*args)
        scope.find(*args)
      end

      def first(*args)
        first_or_last(:first, *args)
      end

      def last(*args)
        first_or_last(:last, *args)
      end

      # Returns the size of the collection
      #
      # If the collection has been already loaded +size+ and +length+ are
      # equivalent. If not and you are going to need the records anyway
      # +length+ will take one less query. Otherwise +size+ is more efficient.
      #
      # This method is abstract in the sense that it relies on
      # +count_records+, which is a method descendants have to provide.
      def size
        if @owner.new_record? && @target
          @target.size
        elsif !loaded? && @target.is_a?(Array)
          unsaved_records = @target.select { |r| r.new_record? }
          unsaved_records.size + count_records
        else
          count_records
        end
      end

      # Returns true if the collection is empty.
      #
      # If the collection has been loaded it is equivalent to <tt>collection.
      # size.zero?</tt>. If the collection has not been loaded, it is equivalent to
      # <tt>collection.count_records == 0</tt>. If the collection has not already been
      # loaded and you are going to fetch the records anyway it is better to
      # check <tt>collection.length.zero?</tt>.
      def empty?
        if loaded?
          size.zero?
        else
          @target.blank? && count_records == 0
        end
      end

      # Replace this collection with +other_array+
      # This will perform a diff and delete/add only records that have changed.
      def replace(other_array)
        other_array.each { |val| raise_on_type_mismatch(val) }

        load_target
        other   = other_array.size < 100 ? other_array : other_array.to_set
        current = @target.size < 100 ? @target : @target.to_set

        delete(@target.select { |v| !other.include?(v) })
        concat(other_array.select { |v| !current.include?(v) })
      end

      def include?(record)
        if record.is_a?(reflection.klass)
          if record.new_record?
            target.include?(record)
          else
            loaded? ? target.include?(record) : scope.exists?(record)
          end
        else
          false
        end
      end

      def any?
        if block_given?
          load_target.any? { |*block_args| yield(*block_args) }
        else
          !empty?
        end
      end

      def to_ary
        load_target.dup
      end
      alias_method :to_a, :to_ary

      def build(attributes = {}, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| build(attr, &block) }
        else
          add_to_target(build_record(attributes)) do |record|
            yield(record) if block_given?
          end
        end
      end

      # Add +records+ to this association.  Returns +self+ so method calls may be chained.
      # Since << flattens its argument list and inserts each record, +push+ and +concat+ behave identically.
      def concat(*records)
        load_target unless owner.new_record?
        concat_records(records)
      end

      def concat_records(*records)
        result = true

        records.flatten.each do |record|
          raise_on_type_mismatch(record)
          add_to_target(record) do |r|
            result &&= insert_record(record) unless owner.new_record?
          end
        end

        result && records
      end

      # Remove all records from this association
      #
      # See delete for more info.
      def delete_all
        # TODO load_target causes extra loads. Can't we just send delete requests?
        delete(load_target).tap do
          reset
          loaded!
        end
      end

      # Remove all records from this association
      #
      # See delete for more info.
      def destroy_all
        destroy(load_target).tap do
          reset
          loaded!
        end
      end

      # Removes +records+ from this association calling +before_remove+ and
      # +after_remove+ callbacks.
      #
      # This method is abstract in the sense that +delete_records+ has to be
      # provided by descendants. Note this method does not imply the records
      # are actually removed from the database, that depends precisely on
      # +delete_records+. They are in any case removed from the collection.
      def delete(*records)
        delete_or_destroy(records, options[:dependent])
      end

      # Destroy +records+ and remove them from this association calling
      # +before_remove+ and +after_remove+ callbacks.
      #
      # Note that this method will _always_ remove records from the database
      # ignoring the +:dependent+ option.
      def destroy(*records)
        records = find(records) if records.any? { |record| record.kind_of?(Fixnum) || record.kind_of?(String) }
        delete_or_destroy(records, :destroy)
      end

      def create(attrs = {})
        if attrs.is_a?(Array)
          attrs.collect { |attr| create(attr) }
        else
          create_record(attrs) do |record|
            yield(record) if block_given?
            record.save
          end
        end
      end

      def create!(attrs = {})
        create_record(attrs) do |record|
          yield(record) if block_given?
          record.save!
        end
      end

      # Count all records using solr. Construct options and pass them with
      # scope to the target class's +count+.
      def count(options = {})
        @reflection.klass.count(:conditions => @counter_query)
      end

      # Sets the target of this proxy to <tt>\target</tt>, and the \loaded flag to +true+.
      def target=(target)
        @target = [target]
        loaded!
      end

      def load_target
        if find_target?
          targets = []

          begin
            targets = find_target
          rescue ObjectNotFoundError, Ldp::Gone => e
            ActiveFedora::Base.logger.error "Solr and Fedora may be out of sync:\n" + e.message if ActiveFedora::Base.logger
            reset
          end

          @target = merge_target_lists(targets, @target)
        end

        loaded!
        target
      end

      def find_target
        # TODO: don't reify, just store the solr results and lazily reify.
        # For now, we set a hard limit of 1000 results.
        records = ActiveFedora::QueryResultBuilder.reify_solr_results(load_from_solr(rows: 1000))
        records.each { |record| set_inverse_instance(record) }
        records
      end

      def merge_target_lists(loaded, existing)
        return loaded if existing.empty?
        return existing if loaded.empty?

        loaded.map do |f|
          i = existing.index(f)
          if i
            existing.delete_at(i).tap do |t|
              keys = ["id"] + t.changes.keys + (f.attribute_names - t.attribute_names)
              # FIXME: this call to attributes causes many NoMethodErrors
              attributes = f.attributes
              (attributes.keys - keys).each do |k|
                t.send("#{k}=", attributes[k])
              end
            end
          else
            f
          end
        end + existing
      end

      # @param opts [Hash] Options that will be passed through to ActiveFedora::SolrService.query.
      def load_from_solr(opts = Hash.new)
        return [] if @finder_query.empty?
        rows = opts.delete(:rows) { count }
        return [] if rows == 0
        SolrService.query(@finder_query, {rows: rows}.merge(opts))
      end

      def add_to_target(record, skip_callbacks = false)
      #  transaction do
          callback(:before_add, record) unless skip_callbacks
          yield(record) if block_given?

          if @reflection.options[:uniq] && index = @target.index(record)
            @target[index] = record
          else
            @target << record
          end

          callback(:after_add, record) unless skip_callbacks
          set_inverse_instance(record)
       # end

        record
      end

      def scope(opts = {})
        scope = super()
        scope.none! if opts.fetch(:nullify, true) && null_scope?
        scope
      end

      def null_scope?
        owner.new_record? && !foreign_key_present?
      end
      protected
        def reset_target!
          @target = Array.new
        end

        def construct_query

          #TODO use primary_key instead of id
          clauses = { find_reflection => @owner.id }
          clauses[:has_model] = @reflection.class_name.constantize.to_class_uri if @reflection.class_name && @reflection.class_name != 'ActiveFedora::Base'
          @counter_query = @finder_query = ActiveFedora::SolrQueryBuilder.construct_query_for_rel(clauses)
        end


      private

        def find_reflection
          return reflection if @reflection.options[:predicate]
          if @reflection.class_name && @reflection.class_name != 'ActiveFedora::Base' && @reflection.macro != :has_and_belongs_to_many
            @reflection.inverse_of || raise("No :inverse_of or :predicate attribute was set or could be inferred for #{@reflection.macro} #{@reflection.name.inspect} on #{@owner.class}")
          else
            raise "Couldn't find reflection"
          end
        end

        def create_record(attributes, raise = false)
          attributes.update(@reflection.options[:conditions]) if @reflection.options[:conditions].is_a?(Hash)
          ensure_owner_is_not_new

          add_to_target(build_record(attributes)) do |record|
            yield(record) if block_given?
            insert_record(record, true, raise)
          end
        end

        def create_scope
          scope.scope_for_create.stringify_keys
        end

        def delete_or_destroy(records, method)
          records = records.flatten
          records.each { |record| raise_on_type_mismatch(record) }
          existing_records = records.select { |r| r.persisted? }

          records.each { |record| callback(:before_remove, record) }
          delete_records(existing_records, method) if existing_records.any?
          records.each do |record|
            target.delete(record)
          end

          records.each { |record| callback(:after_remove, record) }
        end

        def callback(method, record)
          callbacks_for(method).each do |callback|
            case callback
            when Symbol
              @owner.send(callback, record)
            when Proc
              callback.call(@owner, record)
            else
              callback.send(method, @owner, record)
            end
          end
        end

        def callbacks_for(callback_name)
          full_callback_name = "#{callback_name}_for_#{@reflection.name}"
          @owner.class.send(full_callback_name.to_sym) || []
        end

        def ensure_owner_is_not_new
          if @owner.new_record?
            raise ActiveFedora::RecordNotSaved, "You cannot call create unless the parent is saved"
          end
        end

        # Fetches the first/last using solr if possible, otherwise from the target array.
        def first_or_last(type, *args)
          args.shift if args.first.is_a?(Hash) && args.first.empty?

          #collection = fetch_first_or_last_using_find?(args) ? scoped : load_target
          collection = load_target
          collection.send(type, *args).tap do |record|
            set_inverse_instance record if record.is_a? ActiveFedora::Base
          end
        end
    end
  end
end
