module ActiveFedora
  # = Active Fedora Autosave Association
  #
  # +AutosaveAssociation+ is a module that takes care of automatically saving
  # associacted records when their parent is saved. In addition to saving, it
  # also destroys any associated records that were marked for destruction.
  # (See +mark_for_destruction+ and <tt>marked_for_destruction?</tt>).
  #
  # Saving of the parent, its associations, and the destruction of marked
  # associations, all happen inside a transaction. This should never leave the
  # database in an inconsistent state.
  #
  # If validations for any of the associations fail, their error messages will
  # be applied to the parent.
  #
  # Note that it also means that associations marked for destruction won't
  # be destroyed directly. They will however still be marked for destruction.
  #
  # Note that <tt>:autosave => false</tt> is not same as not declaring <tt>:autosave</tt>.
  # When the <tt>:autosave</tt> option is not present new associations are saved.
  #
  # === One-to-many Example
  #
  # When <tt>:autosave</tt> is not declared new children are saved when their parent is saved:
  #
  #   class Post
  #     has_many :comments # :autosave option is no declared
  #   end
  #
  #   post = Post.new(:title => 'ruby rocks')
  #   post.comments.build(:body => 'hello world')
  #   post.save # => saves both post and comment
  #
  #   post = Post.create(:title => 'ruby rocks')
  #   post.comments.build(:body => 'hello world')
  #   post.save # => saves both post and comment
  #
  #   post = Post.create(:title => 'ruby rocks')
  #   post.comments.create(:body => 'hello world')
  #   post.save # => saves both post and comment
  #
  # When <tt>:autosave</tt> is true all children is saved, no matter whether they are new records:
  #
  #   class Post
  #     has_many :comments, :autosave => true
  #   end
  #
  #   post = Post.create(:title => 'ruby rocks')
  #   post.comments.create(:body => 'hello world')
  #   post.comments[0].body = 'hi everyone'
  #   post.save # => saves both post and comment, with 'hi everyone' as body
  #
  # Destroying one of the associated models as part of the parent's save action
  # is as simple as marking it for destruction:
  #
  #   post.comments.last.mark_for_destruction
  #   post.comments.last.marked_for_destruction? # => true
  #   post.comments.length # => 2
  #
  # Note that the model is _not_ yet removed from the database:
  #
  #   id = post.comments.last.id
  #   Comment.find_by_id(id).nil? # => false
  #
  #   post.save
  #   post.reload.comments.length # => 1
  #
  # Now it _is_ removed from the database:
  #
  #   Comment.find_by_id(id).nil? # => true
  #
  # === Validation
  #
  # Children records are validated unless <tt>:validate</tt> is +false+.
  module AutosaveAssociation
    extend ActiveSupport::Concern

    ASSOCIATION_TYPES = [:has_many, :belongs_to, :has_and_belongs_to_many, :directly_contains, :indirectly_contains, :is_a_container].freeze

    module AssociationBuilderExtension # :nodoc:
      def self.valid_options
        [:autosave]
      end

      def self.build(model, reflection)
        model.send(:define_autosave_association_callbacks, reflection) if ASSOCIATION_TYPES.include? reflection.macro
      end
    end

    included do
      Associations::Builder::Association.extensions << AssociationBuilderExtension
    end

    module ClassMethods
      private

        def define_non_cyclic_method(name, reflection, &block)
          define_method(name) do |*_args|
            result = true
            @_already_called ||= {}
            # Loop prevention for validation of associations
            unless @_already_called[[name, reflection.name]]
              begin
                @_already_called[[name, reflection.name]] = true
                result = instance_eval(&block)
              ensure
                @_already_called[[name, reflection.name]] = false
              end
            end

            result
          end
        end

        # Adds validation and save callbacks for the association as specified by
        # the +reflection+.
        #
        # For performance reasons, we don't check whether to validate at runtime.
        # However the validation and callback methods are lazy and those methods
        # get created when they are invoked for the very first time.  However,
        # this can change, for instance, when using nested attributes, which is
        # called _after_ the association has been defined. Since we don't want
        # the callbacks to get defined multiple times, there are guards that
        # check if the save or validation methods have already been defined
        # before actually defining them.
        def define_autosave_association_callbacks(reflection)
          save_method = :"autosave_associated_records_for_#{reflection.name}"
          validation_method = :"validate_associated_records_for_#{reflection.name}"
          collection = reflection.collection?

          unless method_defined?(save_method)
            if collection
              before_save :before_save_collection_association

              define_non_cyclic_method(save_method, reflection) { save_collection_association(reflection) }
              # Doesn't use after_save as that would save associations added in after_create/after_update twice
              after_create save_method
              after_update save_method
            else
              define_non_cyclic_method(save_method, reflection) { save_belongs_to_association(reflection) }
              before_save save_method
            end
          end

          if reflection.validate? && !method_defined?(validation_method)
            method = (collection ? :validate_collection_association : :validate_single_association)
            define_non_cyclic_method(validation_method, reflection) { send(method, reflection) }
            validate validation_method
          end
        end
    end

    # Reloads the attributes of the object as usual and clears <tt>marked_for_destruction</tt> flag.
    def reload
      @marked_for_destruction = false
      @destroyed_by_association = nil
      super
    end

    # Marks this record to be destroyed as part of the parents save transaction.
    # This does _not_ actually destroy the record instantly, rather child record will be destroyed
    # when <tt>parent.save</tt> is called.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for this associated model.
    def mark_for_destruction
      @marked_for_destruction = true
    end

    # Returns whether or not this record will be destroyed as part of the parents save transaction.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for this associated model.
    def marked_for_destruction?
      @marked_for_destruction
    end

    # Records the association that is being destroyed and destroying this
    # record in the process.
    def destroyed_by_association=(reflection)
      @destroyed_by_association = reflection
    end

    # Returns the association for the parent being destroyed.
    #
    # Used to avoid updating the counter cache unnecessarily.
    def destroyed_by_association
      @destroyed_by_association
    end

    # Returns whether or not this record has been changed in any way (including whether
    # any of its nested autosave associations are likewise changed)
    def changed_for_autosave?
      new_record? || changed? || marked_for_destruction? || nested_records_changed_for_autosave?
    end

    private

      # Returns the record for an association collection that should be validated
      # or saved. If +autosave+ is +false+ only new records will be returned,
      # unless the parent is/was a new record itself.
      def associated_records_to_validate_or_save(association, new_record, autosave)
        if new_record
          association&.target
        elsif autosave
          association.target.find_all(&:changed_for_autosave?)
        else
          association.target.find_all(&:new_record?)
        end
      end

      # go through nested autosave associations that are loaded in memory (without loading
      # any new ones), and return true if is changed for autosave
      def nested_records_changed_for_autosave?
        self.class.reflect_on_all_autosave_associations.any? do |reflection|
          association = association_instance_get(reflection.name)
          association && Array(association.target).any?(&:changed_for_autosave?)
        end
      end

      # Validate the association if <tt>:validate</tt> or <tt>:autosave</tt> is
      # turned on for the association.
      def validate_single_association(reflection)
        association = association_instance_get(reflection.name)
        record      = association&.target
        association_valid?(reflection, record) if record
      end

      # Validate the associated records if <tt>:validate</tt> or
      # <tt>:autosave</tt> is turned on for the association specified by
      # +reflection+.
      def validate_collection_association(reflection)
        if association = association_instance_get(reflection.name)
          if records = associated_records_to_validate_or_save(association, new_record?, reflection.options[:autosave])
            records.each { |record| association_valid?(reflection, record) }
          end
        end
      end

      # Returns whether or not the association is valid and applies any errors to
      # the parent, <tt>self</tt>, if it wasn't. Skips any <tt>:autosave</tt>
      # enabled records if they're marked_for_destruction? or destroyed.
      def association_valid?(reflection, record)
        return true if record.destroyed? || record.marked_for_destruction?

        unless valid = record.valid?
          if reflection.options[:autosave]
            record.errors.messages.each do |attribute, messages|
              attribute = "#{reflection.name}.#{attribute}"
              messages.map { |message| errors.add(attribute, message: message) }
            end
          else
            errors.add(reflection.name)
          end
        end
        valid
      end

      # Is used as a before_save callback to check while saving a collection
      # association whether or not the parent was a new record before saving.
      def before_save_collection_association
        @new_record_before_save = new_record?
        true
      end

      # Saves any new associated records, or all loaded autosave associations if
      # <tt>:autosave</tt> is enabled on the association.
      #
      # In addition, it destroys all children that were marked for destruction
      # with mark_for_destruction.
      #
      # This all happens inside a transaction, _if_ the Transactions module is included into
      # ActiveFedora::Base after the AutosaveAssociation module, which it does by default.
      def save_collection_association(reflection)
        if association = association_instance_get(reflection.name)
          autosave = reflection.options[:autosave]

          if records = associated_records_to_validate_or_save(association, @new_record_before_save, autosave)
            records.each do |record|
              next if record.destroyed?

              saved = true

              if autosave && record.marked_for_destruction?
                association.proxy.destroy(record)
              elsif autosave != false && (@new_record_before_save || record.new_record?)
                if autosave
                  saved = association.insert_record(record, false)
                else
                  association.insert_record(record)
                end
              elsif autosave
                saved = record.save(validate: false)
              end

              raise ActiveFedora::Rollback unless saved
            end
          end

          # reconstruct the scope now that we know the owner's id
          association.send(:reset_scope) if association.respond_to?(:reset_scope)
        end
      end

      # Saves the associated record if it's new or <tt>:autosave</tt> is enabled.
      #
      # In addition, it will destroy the association if it was marked for destruction.
      def save_belongs_to_association(reflection)
        association = association_instance_get(reflection.name)
        record      = association&.load_target
        if record && !record.destroyed?
          autosave = reflection.options[:autosave]

          if autosave && record.marked_for_destruction?
            record.destroy
          elsif autosave != false
            saved = record.save(validate: !autosave) if record.new_record? || (autosave && record.changed_for_autosave?)

            if association.updated?
              self[reflection.foreign_key] = record.id
              association.loaded!
            end

            saved if autosave
          end
        end
      end
  end
end
