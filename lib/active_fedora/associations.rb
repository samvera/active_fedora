require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'

module ActiveFedora
  class InverseOfAssociationNotFoundError < RuntimeError #:nodoc:
    def initialize(reflection, associated_class = nil)
      super("Could not find the inverse association for #{reflection.name} (#{reflection.options[:inverse_of].inspect} in #{associated_class.nil? ? reflection.class_name : associated_class.name})")
    end
  end

  module Associations
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    autoload :Association
    autoload :SingularAssociation
    autoload :RDF
    autoload :SingularRDF
    autoload :CollectionAssociation
    autoload :CollectionProxy
    autoload :ContainerProxy

    autoload :HasManyAssociation
    autoload :BelongsToAssociation
    autoload :HasAndBelongsToManyAssociation
    autoload :BasicContainsAssociation
    autoload :HasSubresourceAssociation
    autoload :DirectlyContainsAssociation
    autoload :DirectlyContainsOneAssociation
    autoload :IndirectlyContainsAssociation
    autoload :ContainsAssociation
    autoload :FilterAssociation
    autoload :OrdersAssociation
    autoload :DeleteProxy
    autoload :ContainedFinder
    autoload :RecordComposite
    autoload :IDComposite
    autoload :NullValidator

    module Builder
      autoload :Association,             'active_fedora/associations/builder/association'
      autoload :SingularAssociation,     'active_fedora/associations/builder/singular_association'
      autoload :CollectionAssociation,   'active_fedora/associations/builder/collection_association'

      autoload :BelongsTo,           'active_fedora/associations/builder/belongs_to'
      autoload :HasMany,             'active_fedora/associations/builder/has_many'
      autoload :HasAndBelongsToMany, 'active_fedora/associations/builder/has_and_belongs_to_many'
      autoload :BasicContains,       'active_fedora/associations/builder/basic_contains'
      autoload :HasSubresource,      'active_fedora/associations/builder/has_subresource'
      autoload :DirectlyContains,    'active_fedora/associations/builder/directly_contains'
      autoload :DirectlyContainsOne, 'active_fedora/associations/builder/directly_contains_one'
      autoload :IndirectlyContains,  'active_fedora/associations/builder/indirectly_contains'

      autoload :Property,         'active_fedora/associations/builder/property'
      autoload :SingularProperty, 'active_fedora/associations/builder/singular_property'

      autoload :Aggregation, 'active_fedora/associations/builder/aggregation'
      autoload :Filter, 'active_fedora/associations/builder/filter'
      autoload :Orders, 'active_fedora/associations/builder/orders'
    end

    eager_autoload do
      autoload :AssociationScope
    end

    # Clears out the association cache.
    def clear_association_cache #:nodoc:
      @association_cache.clear if persisted?
    end

    # :nodoc:
    attr_reader :association_cache

    # Returns the association instance for the given name, instantiating it if it doesn't already exist
    def association(name) #:nodoc:
      association = association_instance_get(name)

      if association.nil?
        reflection  = self.class._reflect_on_association(name)
        association = reflection.association_class.new(self, reflection) if reflection
        association_instance_set(name, association) if association
      end

      association
    end

    def delete(*)
      reflections.each_pair do |name, reflection|
        association(name.to_sym).delete_all if reflection.macro == :has_many
      end
      super
    end

    private

      # Returns the specified association instance if it responds to :loaded?, nil otherwise.
      def association_instance_get(name)
        raise "use a symbol" if name.is_a? String
        @association_cache[name]
      end

      # Set the specified association instance.
      def association_instance_set(name, association)
        @association_cache[name] = association
      end

      module ClassMethods
        # This method is used to declare this resource acts like an LDP BasicContainer
        #
        # @param [Hash] options
        # @option options [String] :class_name ('ActiveFedora::File') The name of the
        #   class that will represent the contained resources
        #
        # example:
        #   class FooHistory < ActiveFedora::Base
        #     is_a_container class_name: 'Thing'
        #   end
        #
        def is_a_container(options = {})
          defaults = { class_name: 'ActiveFedora::File',
                       predicate: ::RDF::Vocab::LDP.contains }
          Builder::BasicContains.build(self, :contains, defaults.merge(options))
        end

        # This method is used to declare an ldp:DirectContainer on a resource
        # you must specify an is_member_of_relation or a has_member_relation
        #
        # @param [String] name the handle to refer to this child as
        # @param [Hash] options
        # @option options [String] :class_name ('ActiveFedora::File') The name of the class that will represent the contained resources
        # @option options [RDF::URI] :has_member_relation the rdf predicate to use for the ldp:hasMemberRelation
        # @option options [RDF::URI] :is_member_of_relation the rdf predicate to use for the ldp:isMemberOfRelation
        #
        # example:
        #   class FooHistory < ActiveFedora::Base
        #     directly_contains :files, has_member_relation:
        #         ::RDF::URI.new("http://example.com/hasFiles"), class_name: 'Thing'
        #     directly_contains :other_stuff, is_member_of_relation:
        #         ::RDF::URI.new("http://example.com/isContainedBy"), class_name: 'Thing'
        #   end
        #
        def directly_contains(name, options = {})
          Builder::DirectlyContains.build(self, name, { class_name: 'ActiveFedora::File' }.merge(options))
        end

        def directly_contains_one(name, options = {})
          Builder::DirectlyContainsOne.build(self, name, { class_name: 'ActiveFedora::File' }.merge(options))
        end

        # This method is used to declare an ldp:IndirectContainer on a resource
        # you must specify an is_member_of_relation or a has_member_relation
        #
        # @param [String] name the handle to refer to this child as
        # @param [Hash] options
        # @option options [String] :class_name ('ActiveFedora::File') The name of the class that will represent the contained resources
        # @option options [RDF::URI] :has_member_relation the rdf predicate to use for the ldp:hasMemberRelation
        # @option options [RDF::URI] :is_member_of_relation the rdf predicate to use for the ldp:isMemberOfRelation
        # @option options [RDF::URI] :inserted_content_relation the rdf predicate to use for the ldp:insertedContentRelation
        # @option options [String] :through name of a class to represent the interstitial node
        # @option options [Symbol] :foreign_key property that points at the remote resource
        #
        # example:
        #   class Proxy < ActiveFedora::Base
        #     belongs_to :proxy_for, predicate: ::RDF::URI.new('http://www.openarchives.org/ore/terms/proxyFor'), class_name: 'ActiveFedora::Base'
        #   end
        #
        #   class FooHistory < ActiveFedora::Base
        #     indirectly_contains :files, has_member_relation: RDF::Vocab::ORE.aggregates,
        #       inserted_content_relation: RDF::Vocab::ORE.proxyFor, class_name: 'Thing',
        #       through: 'Proxy', foreign_key: :proxy_for
        #
        #     indirectly_contains :other_stuff, is_member_of_relation:
        #         ::RDF::URI.new("http://example.com/isContainedBy"), class_name: 'Thing',
        #         through: 'Proxy', foreign_key: :proxy_for
        #   end
        #
        def indirectly_contains(name, options = {})
          Builder::IndirectlyContains.build(self, name, options)
        end

        def has_many(name, options = {})
          Builder::HasMany.build(self, name, options)
        end

        # This method is used to specify the details of a contained resource.
        # Pass the name as the first argument and a hash of options as the second argument
        # Note that this method doesn't actually execute the block, but stores it, to be executed
        # by any the implementation of the resource(specified as :class_name)
        #
        # @param [String] name the handle to refer to this child as
        # @param [Hash] options
        # @option options [Class] :class_name The class that will represent this child, should extend ``ActiveFedora::File'' or ``ActiveFedora::Base''
        # @option options [String] :url
        # @option options [Boolean] :autocreate Always create this resource on new objects
        # @yield block executed by some types of child resources
        def has_subresource(name, options = {}, &block)
          options[:block] = block if block
          raise ArgumentError, "You must provide a path name (f.k.a. dsid) for the resource" unless name
          Associations::Builder::HasSubresource.build(self, name.to_sym, options)
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
        # [:predicate]
        #   the association predicate to use when storing the association +REQUIRED+
        # [:class_name]
        #   Specify the class name of the association. Use it only if that name can't be inferred
        #   from the association name. So <tt>has_one :author</tt> will by default be linked to the Author class, but
        #   if the real class name is Person, you'll have to specify it with this option.
        #
        # Option examples:
        #   belongs_to :firm, predicate: OurVocab.clientOf
        #   belongs_to :author, class_name: "Person", predicate: OurVocab.authorOf
        def belongs_to(name, options = {})
          Builder::BelongsTo.build(self, name, options)

          Builder::SingularProperty.build(self, name, options)
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
        # [:predicate]
        #   <b>REQUIRED</b> Specify the predicate to use when storing the relationship.
        # [:inverse_of]
        #   Specify the predicate to use when storing the relationship on the foreign object. If it is not provided, the relationship will not set the foriegn association.
        #
        # Option examples:
        #   has_and_belongs_to_many :projects, predicate: OurVocab.worksOn
        #   has_and_belongs_to_many :nations, class_name: "Country", predicate: OurVocab.isCitizenOf
        #   has_and_belongs_to_many :topics, predicate: RDF::FOAF.isPrimaryTopicOf, inverse_of: :is_topic_of
        def has_and_belongs_to_many(name, options = {})
          Builder::HasAndBelongsToMany.build(self, name, options)
          Builder::Property.build(self, name, options.slice(:class_name, :predicate))
        end

        ##
        # Allows ordering of an association
        # @example
        #   class Image < ActiveFedora::Base
        #     contains :list_resource, class_name:
        #       "ActiveFedora::Aggregation::ListSource"
        #     orders :generic_files, through: :list_resource
        #   end
        def orders(name, options = {})
          Builder::Orders.build(self, name, options)
        end

        ##
        # Convenience method for building an ordered aggregation.
        # @example
        #   class Image < ActiveFedora::Base
        #     ordered_aggregation :members, through: :list_source
        #   end
        def ordered_aggregation(name, options = {})
          Builder::Aggregation.build(self, name, options)
        end

        ##
        # Create an association filter on the class
        # @example
        #   class Image < ActiveFedora::Base
        #     aggregates :generic_files
        #     filters_association :generic_files, as: :large_files, condition: :big_file?
        #   end
        def filters_association(extending_from, options = {})
          name = options.delete(:as)
          Builder::Filter.build(self, name, options.merge(extending_from: extending_from))
        end
      end
  end
end
