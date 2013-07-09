require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'

module ActiveFedora
  module Associations
    extend ActiveSupport::Concern

    autoload :HasManyAssociation, 'active_fedora/associations/has_many_association'
    autoload :BelongsToAssociation, 'active_fedora/associations/belongs_to_association'
    autoload :HasAndBelongsToManyAssociation, 'active_fedora/associations/has_and_belongs_to_many_association'


    autoload :AssociationCollection, 'active_fedora/associations/association_collection'
    autoload :AssociationProxy, 'active_fedora/associations/association_proxy'

    # Clears out the association cache.
    def clear_association_cache #:nodoc:
      @association_cache.clear if persisted?
    end

    # :nodoc:
    attr_reader :association_cache
    
    private 

      # Returns the specified association instance if it responds to :loaded?, nil otherwise.
      def association_instance_get(name)
        @association_cache[name.to_sym]
      end

      # Set the specified association instance.
      def association_instance_set(name, association)
        @association_cache[name] = association
      end

    module ClassMethods

      def has_many(association_id, options={})
        reflection = create_has_many_reflection(association_id, options)
        add_association_callbacks(reflection.name, reflection.options)
        collection_accessor_methods(reflection, HasManyAssociation)
      end

  
      # Specifies a one-to-one association with another class. This method should only be used
      # if this class contains the foreign key.
      #
      # Methods will be added for retrieval and query for a single associated object, for which
      # this object holds an id:
      #
      # [association()]
      #   Returns the associated object. +nil+ is returned if none is found.
      # [association=(associate)]
      #   Assigns the associate object, extracts the primary key, and sets it as the foreign key.
      #
      # (+association+ is replaced with the symbol passed as the first argument, so
      # <tt>belongs_to :author</tt> would add among others <tt>author.nil?</tt>.)
      #
      # === Example
      #
      # A Post class declares <tt>belongs_to :author</tt>, which will add:
      # * <tt>Post#author</tt> (similar to <tt>Author.find(author_id)</tt>)
      # * <tt>Post#author=(author)</tt> 
      # The declaration can also include an options hash to specialize the behavior of the association.
      #
      # === Options
      #
      # [:property]
      #   the association predicate to use when storing the association +REQUIRED+
      # [:class_name]
      #   Specify the class name of the association. Use it only if that name can't be inferred
      #   from the association name. So <tt>has_one :author</tt> will by default be linked to the Author class, but
      #   if the real class name is Person, you'll have to specify it with this option.
      #
      # Option examples:
      #   belongs_to :firm, :property => :client_of
      #   belongs_to :author, :class_name => "Person", :property => :author_of
      def belongs_to(association_id, options = {})
        raise "You must specify a property name for #{name}" if !options[:property]
        reflection = create_belongs_to_reflection(association_id, options)

        association_accessor_methods(reflection, BelongsToAssociation)
        association_constructor_method(:build,  reflection, BelongsToAssociation)
        association_constructor_method(:create, reflection, BelongsToAssociation)
        #configure_dependency_for_belongs_to(reflection)
      end


      # Specifies a many-to-many relationship with another class. The relatioship is written to both classes simultaneously.
      #
      # Adds the following methods for retrieval and query:
      #
      # [collection(force_reload = false)]
      #   Returns an array of all the associated objects.
      #   An empty array is returned if none are found.
      # [collection<<(object, ...)]
      #   Adds one or more objects to the collection by creating associations in the join table
      #   (<tt>collection.push</tt> and <tt>collection.concat</tt> are aliases to this method).
      #   Note that this operation instantly fires update sql without waiting for the save or update call on the
      #   parent object.
      # [collection.delete(object, ...)]
      #   Removes one or more objects from the collection by removing their associations from the join table.
      #   This does not destroy the objects.
      # [collection=objects]
      #   Replaces the collection's content by deleting and adding objects as appropriate.
      # [collection_singular_ids]
      #   Returns an array of the associated objects' ids.
      # [collection_singular_ids=ids]
      #   Replace the collection by the objects identified by the primary keys in +ids+.
      # [collection.clear]
      #   Removes every object from the collection. This does not destroy the objects.
      # [collection.empty?]
      #   Returns +true+ if there are no associated objects.
      # [collection.size]
      #   Returns the number of associated objects.
      #
      # (+collection+ is replaced with the symbol passed as the first argument, so
      # <tt>has_and_belongs_to_many :categories</tt> would add among others <tt>categories.empty?</tt>.)
      #
      # === Example
      #
      # A Developer class declares <tt>has_and_belongs_to_many :projects</tt>, which will add:
      # * <tt>Developer#projects</tt>
      # * <tt>Developer#projects<<</tt>
      # * <tt>Developer#projects.delete</tt>
      # * <tt>Developer#projects=</tt>
      # * <tt>Developer#project_ids</tt>
      # * <tt>Developer#project_ids=</tt>
      # * <tt>Developer#projects.clear</tt>
      # * <tt>Developer#projects.empty?</tt>
      # * <tt>Developer#projects.size</tt>
      # * <tt>Developer#projects.find(id)</tt>
      # * <tt>Developer#projects.exists?(...)</tt>
      # The declaration may include an options hash to specialize the behavior of the association.
      #
      # === Options
      #
      # [:class_name]
      #   Specify the class name of the association. Use it only if that name can't be inferred
      #   from the association name. So <tt>has_and_belongs_to_many :projects</tt> will by default be linked to the
      #   Project class, but if the real class name is SuperProject, you'll have to specify it with this option.
      # [:property]
      #   <b>REQUIRED</b> Specify the predicate to use when storing the relationship.
      # [:inverse_of]
      #   Specify the predicate to use when storing the relationship on the foreign object. If it is not provided, the relationship will not set the foriegn association.
      #
      # Option examples:
      #   has_and_belongs_to_many :projects, :property=>:works_on
      #   has_and_belongs_to_many :nations, :class_name => "Country", :property=>:is_citizen_of
      #   has_and_belongs_to_many :topics, :property=>:has_topic, :inverse_of=>:is_topic_of
      def has_and_belongs_to_many(association_id, options = {}, &extension)
        reflection = create_has_and_belongs_to_many_reflection(association_id, options, &extension)
        collection_accessor_methods(reflection, HasAndBelongsToManyAssociation)
        #configure_after_destroy_method_for_has_and_belongs_to_many(reflection)
        add_association_callbacks(reflection.name, options)
      end


      private 

        def create_has_many_reflection(association_id, options)
          create_reflection(:has_many, association_id, options, self)
          #collection_accessor_methods(reflection, HasManyAssociation)
        end

        def create_belongs_to_reflection(association_id, options)
          create_reflection(:belongs_to, association_id, options, self)
        end

        def create_has_and_belongs_to_many_reflection(association_id, options)
          create_reflection(:has_and_belongs_to_many, association_id, options, self)
        end

        def add_association_callbacks(association_name, options)
          callbacks = %w(before_add after_add before_remove after_remove)
          callbacks.each do |callback_name|
            full_callback_name = "#{callback_name}_for_#{association_name}"
            defined_callbacks = options[callback_name.to_sym]
            class_attribute full_callback_name.to_sym
            if options.has_key?(callback_name.to_sym)
              self.send((full_callback_name +'=').to_sym, [defined_callbacks].flatten)
            else
              self.send((full_callback_name +'=').to_sym, [])
            end
          end
        end

        def association_accessor_methods(reflection, association_proxy_class)
          redefine_method(reflection.name) do |*params|
            force_reload = params.first unless params.empty?
            association = association_instance_get(reflection.name)

            if association.nil? || force_reload
              association = association_proxy_class.new(self, reflection)
              retval = force_reload ? reflection.klass.uncached { association.reload } : association.reload
              if retval.nil? and association_proxy_class == BelongsToAssociation
                association_instance_set(reflection.name, nil)
                return nil
              end
              association_instance_set(reflection.name, association)
            end

            association.target.nil? ? nil : association
          end

          redefine_method("loaded_#{reflection.name}?") do
            association = association_instance_get(reflection.name)
            association && association.loaded?
          end

          redefine_method("#{reflection.name}=") do |new_value|
            association = association_instance_get(reflection.name)

            if association.nil? || association.target != new_value
              association = association_proxy_class.new(self, reflection)
            end

            association.replace(new_value)
            association_instance_set(reflection.name, new_value.nil? ? nil : association)
          end

          redefine_method("set_#{reflection.name}_target") do |target|
            return if target.nil? and association_proxy_class == BelongsToAssociation
            association = association_proxy_class.new(self, reflection)
            association.target = target
            association_instance_set(reflection.name, association)
          end

          redefine_method("#{reflection.name}_id=") do |new_value|
            obj =  new_value.blank? ? nil : reflection.klass.find(new_value)
            send("#{reflection.name}=", obj)
          end
          redefine_method("#{reflection.name}_id") do 
            obj = send("#{reflection.name}")
            obj.pid if obj
          end
        end


        def collection_reader_method(reflection, association_proxy_class)
          redefine_method(reflection.name) do |*params|
            
            if (params.first.is_a?(Hash) && params.first[:response_format] == :solr)
              load_from_solr = true
              force_reload = false 
            else 
              force_reload = params.first unless params.empty?
            end
            association = association_instance_get(reflection.name)
            unless association
              association = association_proxy_class.new(self, reflection)
              association_instance_set(reflection.name, association)
            end

            association.reload if force_reload
            return association.load_from_solr if load_from_solr

            association
          end

          redefine_method("#{reflection.name.to_s.singularize}_ids") do
              send(reflection.name).map { |r| r.pid }
          end

        end


        def collection_accessor_methods(reflection, association_proxy_class, writer = true)
          collection_reader_method(reflection, association_proxy_class)

          if writer
            redefine_method("#{reflection.name}=") do |new_value|
              # Loads proxy class instance (defined in collection_reader_method) if not already loaded
              association = send(reflection.name)
              association.replace(new_value)
              association
            end

            redefine_method("#{reflection.name.to_s.singularize}_ids=") do |new_value|
              ids = (new_value || []).reject { |nid| nid.blank? }
              #TODO, like this when find() can return multiple records
              #send("#{reflection.name}=", reflection.klass.find(ids))
              send("#{reflection.name}=", ids.collect { |id| reflection.klass.find(id)})
            end
          end
        end

        def association_constructor_method(constructor, reflection, association_proxy_class)
          redefine_method("#{constructor}_#{reflection.name}") do |*params|
            attributees      = params.first unless params.empty?
            replace_existing = params[1].nil? ? true : params[1]
            association      = association_instance_get(reflection.name)

            unless association
              association = association_proxy_class.new(self, reflection)
              association_instance_set(reflection.name, association)
            end

            # if association_proxy_class == HasOneAssociation
            #   association.send(constructor, attributees, replace_existing)
            # else
            association.send(constructor, attributees)
            #end
          end
        end
    end
  end
end
