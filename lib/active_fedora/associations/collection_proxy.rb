# -*- coding: utf-8 -*-
module ActiveFedora
  module Associations
    # Association proxies in Active Fedora are middlemen between the object that
    # holds the association, known as the <tt>@owner</tt>, and the actual associated
    # object, known as the <tt>@target</tt>. The kind of association any proxy is
    # about is available in <tt>@reflection</tt>. That's an instance of the class
    # ActiveFedora::Reflection::AssociationReflection.
    #
    # For example, given
    #
    #   class Blog < ActiveFedora::Base
    #     has_many :posts
    #   end
    #
    #   blog = Blog.find(:first)
    #
    # the association proxy in <tt>blog.posts</tt> has the object in +blog+ as
    # <tt>@owner</tt>, the collection of its posts as <tt>@target</tt>, and
    # the <tt>@reflection</tt> object represents a <tt>:has_many</tt> macro.
    #
    # This class has most of the basic instance methods removed, and delegates
    # unknown methods to <tt>@target</tt> via <tt>method_missing</tt>. As a
    # corner case, it even removes the +class+ method and that's why you get
    #
    #   blog.posts.class # => Array
    #
    # though the object behind <tt>blog.posts</tt> is not an Array, but an
    # ActiveFedora::Associations::HasManyAssociation.
    #
    # The <tt>@target</tt> object is not \loaded until needed. For example,
    #
    #   blog.posts.count
    #
    # is computed directly through Solr and does not trigger by itself the
    # instantiation of the actual post records.
    class CollectionProxy < Relation # :nodoc:
      def initialize(association)
        @association = association
        super association.klass
        merge! association.scope(nullify: false)
      end

      def target
        @association.target
      end

      def load_target
        @association.load_target
      end

      def load_from_solr(opts = {})
        @association.load_from_solr(opts)
      end

      def loaded?
        @association.loaded?
      end

      # Works in two ways.
      #
      # *First:* Specify a subset of fields to be selected from the result set.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.select(:name)
      #   # => [
      #   #      #<Pet id: nil, name: "Fancy-Fancy">,
      #   #      #<Pet id: nil, name: "Spook">,
      #   #      #<Pet id: nil, name: "Choo-Choo">
      #   #    ]
      #
      #   person.pets.select([:id, :name])
      #   # => [
      #   #      #<Pet id: 1, name: "Fancy-Fancy">,
      #   #      #<Pet id: 2, name: "Spook">,
      #   #      #<Pet id: 3, name: "Choo-Choo">
      #   #    ]
      #
      # Be careful because this also means you're initializing a model
      # object with only the fields that you've selected. If you attempt
      # to access a field that is not in the initialized record you'll
      # receive:
      #
      #   person.pets.select(:name).first.person_id
      #   # => ActiveModel::MissingAttributeError: missing attribute: person_id
      #
      # *Second:* You can pass a block so it can be used just like Array#select.
      # This build an array of objects from the database for the scope,
      # converting them into an array and iterating through them using
      # Array#select.
      #
      #   person.pets.select { |pet| pet.name =~ /oo/ }
      #   # => [
      #   #      #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #      #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.select(:name) { |pet| pet.name =~ /oo/ }
      #   # => [
      #   #      #<Pet id: 2, name: "Spook">,
      #   #      #<Pet id: 3, name: "Choo-Choo">
      #   #    ]
      def select(select = nil, &block)
        @association.select(select, &block)
      end

      # Finds an object in the collection responding to the +id+. Uses the same
      # rules as <tt>ActiveFedora::Base.find</tt>. Returns <tt>ActiveFedora::ObjectNotFoundError</tt>
      # error if the object can not be found.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.find(1) # => #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>
      #   person.pets.find(4) # => ActiveFedora::ObjectNotFoundError: Couldn't find Pet with id=4
      #
      #   person.pets.find(2) { |pet| pet.name.downcase! }
      #   # => #<Pet id: 2, name: "fancy-fancy", person_id: 1>
      #
      #   person.pets.find(2, 3)
      #   # => [
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      def find(*args, &block)
        @association.find(*args, &block)
      end

      # Returns the first record, or the first +n+ records, from the collection.
      # If the collection is empty, the first form returns +nil+, and the second
      # form returns an empty array.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.first # => #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>
      #
      #   person.pets.first(2)
      #   # => [
      #   #      #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #      #<Pet id: 2, name: "Spook", person_id: 1>
      #   #    ]
      #
      #   another_person_without.pets          # => []
      #   another_person_without.pets.first    # => nil
      #   another_person_without.pets.first(3) # => []
      def first(*args)
        @association.first(*args)
      end

      # Returns the last record, or the last +n+ records, from the collection.
      # If the collection is empty, the first form returns +nil+, and the second
      # form returns an empty array.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.last # => #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #
      #   person.pets.last(2)
      #   # => [
      #   #      #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #      #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   another_person_without.pets         # => []
      #   another_person_without.pets.last    # => nil
      #   another_person_without.pets.last(3) # => []
      def last(*args)
        @association.last(*args)
      end

      # Returns a new object of the collection type that has been instantiated
      # with +attributes+ and linked to this object, but have not yet been saved.
      # You can pass an array of attributes hashes, this will return an array
      # with the new objects.
      #
      #   class Person
      #     has_many :pets
      #   end
      #
      #   person.pets.build
      #   # => #<Pet id: nil, name: nil, person_id: 1>
      #
      #   person.pets.build(name: 'Fancy-Fancy')
      #   # => #<Pet id: nil, name: "Fancy-Fancy", person_id: 1>
      #
      #   person.pets.build([{name: 'Spook'}, {name: 'Choo-Choo'}, {name: 'Brain'}])
      #   # => [
      #   #      #<Pet id: nil, name: "Spook", person_id: 1>,
      #   #      #<Pet id: nil, name: "Choo-Choo", person_id: 1>,
      #   #      #<Pet id: nil, name: "Brain", person_id: 1>
      #   #    ]
      #
      #   person.pets.size  # => 5 # size of the collection
      #   person.pets.count # => 0 # count from database
      def build(attributes = {}, &block)
        @association.build(attributes, &block)
      end

      # Returns a new object of the collection type that has been instantiated with
      # attributes, linked to this object and that has already been saved (if it
      # passes the validations).
      #
      #   class Person
      #     has_many :pets
      #   end
      #
      #   person.pets.create(name: 'Fancy-Fancy')
      #   # => #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>
      #
      #   person.pets.create([{name: 'Spook'}, {name: 'Choo-Choo'}])
      #   # => [
      #   #      #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #      #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.size  # => 3
      #   person.pets.count # => 3
      #
      #   person.pets.find(1, 2, 3)
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      def create(attributes = {}, &block)
        @association.create(attributes, &block)
      end

      # Like +create+, except that if the record is invalid, raises an exception.
      #
      #   class Person
      #     has_many :pets
      #   end
      #
      #   class Pet
      #     validates :name, presence: true
      #   end
      #
      #   person.pets.create!(name: nil)
      #   # => ActiveFedora::RecordInvalid: Validation failed: Name can't be blank
      def create!(attributes = {}, &block)
        @association.create!(attributes, &block)
      end

      # Add one or more records to the collection by setting their foreign keys
      # to the association's primary key. Since << flattens its argument list and
      # inserts each record, +push+ and +concat+ behave identically. Returns +self+
      # so method calls may be chained.
      #
      #   class Person < ActiveFedora::Base
      #     pets :has_many
      #   end
      #
      #   person.pets.size # => 0
      #   person.pets.concat(Pet.new(name: 'Fancy-Fancy'))
      #   person.pets.concat(Pet.new(name: 'Spook'), Pet.new(name: 'Choo-Choo'))
      #   person.pets.size # => 3
      #
      #   person.id # => 1
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.concat([Pet.new(name: 'Brain'), Pet.new(name: 'Benny')])
      #   person.pets.size # => 5
      def concat(*records)
        @association.concat(*records)
      end

      # Replace this collection with +other_array+. This will perform a diff
      # and delete/add only records that have changed.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets
      #   # => [#<Pet id: 1, name: "Gorby", group: "cats", person_id: 1>]
      #
      #   other_pets = [Pet.new(name: 'Puff', group: 'celebrities']
      #
      #   person.pets.replace(other_pets)
      #
      #   person.pets
      #   # => [#<Pet id: 2, name: "Puff", group: "celebrities", person_id: 1>]
      #
      # If the supplied array has an incorrect association type, it raises
      # an <tt>ActiveFedora::AssociationTypeMismatch</tt> error:
      #
      #   person.pets.replace(["doo", "ggie", "gaga"])
      #   # => ActiveFedora::AssociationTypeMismatch: Pet expected, got String
      def replace(other_array)
        @association.replace(other_array)
      end

      # Deletes all the records from the collection. For +has_many+ associations,
      # the deletion is done according to the strategy specified by the <tt>:dependent</tt>
      # option. Returns an array with the deleted records.
      #
      # If no <tt>:dependent</tt> option is given, then it will follow the
      # default strategy. The default strategy is <tt>:nullify</tt>. This
      # sets the foreign keys to <tt>NULL</tt>. For, +has_many+ <tt>:through</tt>,
      # the default strategy is +delete_all+.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets # dependent: :nullify option by default
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete_all
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.size # => 0
      #   person.pets      # => []
      #
      #   Pet.find(1, 2, 3)
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: nil>,
      #   #       #<Pet id: 2, name: "Spook", person_id: nil>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: nil>
      #   #    ]
      #
      # If it is set to <tt>:destroy</tt> all the objects from the collection
      # are removed by calling their +destroy+ method. See +destroy+ for more
      # information.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets, dependent: :destroy
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete_all
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   Pet.find(1, 2, 3)
      #   # => ActiveFedora::ObjectNotFoundError
      #
      # If it is set to <tt>:delete_all</tt>, all the objects are deleted
      # *without* calling their +destroy+ method.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets, dependent: :delete_all
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete_all
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   Pet.find(1, 2, 3)
      #   # => ActiveFedora::ObjectNotFoundError
      def delete_all
        @association.delete_all
      end

      # Deletes the records of the collection directly from the database.
      # This will _always_ remove the records ignoring the +:dependent+
      # option.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.destroy_all
      #
      #   person.pets.size # => 0
      #   person.pets      # => []
      #
      #   Pet.find(1) # => Couldn't find Pet with id=1
      def destroy_all
        @association.destroy_all
      end

      # Deletes the +records+ supplied and removes them from the collection. For
      # +has_many+ associations, the deletion is done according to the strategy
      # specified by the <tt>:dependent</tt> option. Returns an array with the
      # deleted records.
      #
      # If no <tt>:dependent</tt> option is given, then it will follow the default
      # strategy. The default strategy is <tt>:nullify</tt>. This sets the foreign
      # keys to <tt>NULL</tt>. For, +has_many+ <tt>:through</tt>, the default
      # strategy is +delete_all+.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets # dependent: :nullify option by default
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete(Pet.find(1))
      #   # => [#<Pet id: 1, name: "Fancy-Fancy", person_id: 1>]
      #
      #   person.pets.size # => 2
      #   person.pets
      #   # => [
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   Pet.find(1)
      #   # => #<Pet id: 1, name: "Fancy-Fancy", person_id: nil>
      #
      # If it is set to <tt>:destroy</tt> all the +records+ are removed by calling
      # their +destroy+ method. See +destroy+ for more information.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets, dependent: :destroy
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete(Pet.find(1), Pet.find(3))
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.size # => 1
      #   person.pets
      #   # => [#<Pet id: 2, name: "Spook", person_id: 1>]
      #
      #   Pet.find(1, 3)
      #   # => ActiveFedora::ObjectNotFoundError: Couldn't find all Pets with IDs (1, 3)
      #
      # If it is set to <tt>:delete_all</tt>, all the +records+ are deleted
      # *without* calling their +destroy+ method.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets, dependent: :delete_all
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete(Pet.find(1))
      #   # => [#<Pet id: 1, name: "Fancy-Fancy", person_id: 1>]
      #
      #   person.pets.size # => 2
      #   person.pets
      #   # => [
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   Pet.find(1)
      #   # => ActiveFedora::ObjectNotFoundError: Couldn't find Pet with id=1
      #
      # You can pass +Integer+ or +String+ values, it finds the records
      # responding to the +id+ and executes delete on them.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.delete("1")
      #   # => [#<Pet id: 1, name: "Fancy-Fancy", person_id: 1>]
      #
      #   person.pets.delete(2, 3)
      #   # => [
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      def delete(*records)
        @association.delete(*records)
      end

      # Destroys the +records+ supplied and removes them from the collection.
      # This method will _always_ remove record from the database ignoring
      # the +:dependent+ option. Returns an array with the removed records.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.destroy(Pet.find(1))
      #   # => [#<Pet id: 1, name: "Fancy-Fancy", person_id: 1>]
      #
      #   person.pets.size # => 2
      #   person.pets
      #   # => [
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.destroy(Pet.find(2), Pet.find(3))
      #   # => [
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.size  # => 0
      #   person.pets       # => []
      #
      #   Pet.find(1, 2, 3) # => ActiveFedora::ObjectNotFoundError: Couldn't find all Pets with IDs (1, 2, 3)
      #
      # You can pass +Integer+ or +String+ values, it finds the records
      # responding to the +id+ and then deletes them from the database.
      #
      #   person.pets.size # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 4, name: "Benny", person_id: 1>,
      #   #       #<Pet id: 5, name: "Brain", person_id: 1>,
      #   #       #<Pet id: 6, name: "Boss",  person_id: 1>
      #   #    ]
      #
      #   person.pets.destroy("4")
      #   # => #<Pet id: 4, name: "Benny", person_id: 1>
      #
      #   person.pets.size # => 2
      #   person.pets
      #   # => [
      #   #       #<Pet id: 5, name: "Brain", person_id: 1>,
      #   #       #<Pet id: 6, name: "Boss",  person_id: 1>
      #   #    ]
      #
      #   person.pets.destroy(5, 6)
      #   # => [
      #   #       #<Pet id: 5, name: "Brain", person_id: 1>,
      #   #       #<Pet id: 6, name: "Boss",  person_id: 1>
      #   #    ]
      #
      #   person.pets.size  # => 0
      #   person.pets       # => []
      #
      #   Pet.find(4, 5, 6) # => ActiveFedora::ObjectNotFoundError: Couldn't find all Pets with IDs (4, 5, 6)
      def destroy(*records)
        @association.destroy(*records)
      end

      # Specifies whether the records should be unique or not.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.select(:name)
      #   # => [
      #   #      #<Pet name: "Fancy-Fancy">,
      #   #      #<Pet name: "Fancy-Fancy">
      #   #    ]
      #
      #   person.pets.select(:name).uniq
      #   # => [#<Pet name: "Fancy-Fancy">]
      def uniq
        @association.uniq
      end

      # Count all records using Solr.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.count # => 3
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      def count(options = {})
        @association.count(options)
      end

      # Returns the size of the collection. If the collection hasn't been loaded,
      # it executes a solr query to find the matching records. Else it calls
      # <tt>collection.size</tt>.
      #
      # If the collection has been already loaded +size+ and +length+ are
      # equivalent. If not and you are going to need the records anyway
      # +length+ will take one less query. Otherwise +size+ is more efficient.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.size # => 3
      #   # queries solr for the number of matching records where "person_id_ssi" = 1
      #
      #   person.pets # This will execute a solr query
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      #
      #   person.pets.size # => 3
      #   # Because the collection is already loaded, this will behave like
      #   # collection.size and no Solr count query is executed.
      def size
        @association.size
      end

      # Returns the size of the collection calling +size+ on the target.
      # If the collection has been already loaded, +length+ and +size+ are
      # equivalent. If not and you are going to need the records anyway this
      # method will take one less query. Otherwise +size+ is more efficient.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.length # => 3
      #   # queries solr for the number of matching records where "person_id_ssi" = 1
      #
      #   # Because the collection is loaded, you can
      #   # call the collection with no additional queries:
      #   person.pets
      #   # => [
      #   #       #<Pet id: 1, name: "Fancy-Fancy", person_id: 1>,
      #   #       #<Pet id: 2, name: "Spook", person_id: 1>,
      #   #       #<Pet id: 3, name: "Choo-Choo", person_id: 1>
      #   #    ]
      def length
        @association.length
      end

      # Returns +true+ if the collection is empty. If the collection has been
      # loaded or the <tt>:counter_sql</tt> option is provided, it is equivalent
      # to <tt>collection.size.zero?</tt>. If the collection has not been loaded,
      # it is equivalent to <tt>collection.exists?</tt>. If the collection has
      # not already been loaded and you are going to fetch the records anyway it
      # is better to check <tt>collection.length.zero?</tt>.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.count  # => 1
      #   person.pets.empty? # => false
      #
      #   person.pets.delete_all
      #
      #   person.pets.count  # => 0
      #   person.pets.empty? # => true
      def empty?
        @association.empty?
      end

      # Returns +true+ if the collection is not empty.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.count # => 0
      #   person.pets.any?  # => false
      #
      #   person.pets << Pet.new(name: 'Snoop')
      #   person.pets.count # => 0
      #   person.pets.any?  # => true
      #
      # You can also pass a block to define criteria. The behavior
      # is the same, it returns true if the collection based on the
      # criteria is not empty.
      #
      #   person.pets
      #   # => [#<Pet name: "Snoop", group: "dogs">]
      #
      #   person.pets.any? do |pet|
      #     pet.group == 'cats'
      #   end
      #   # => false
      #
      #   person.pets.any? do |pet|
      #     pet.group == 'dogs'
      #   end
      #   # => true
      def any?(&block)
        @association.any?(&block)
      end

      # Returns true if the collection has more than one record.
      # Equivalent to <tt>collection.size > 1</tt>.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets.count #=> 1
      #   person.pets.many? #=> false
      #
      #   person.pets << Pet.new(name: 'Snoopy')
      #   person.pets.count #=> 2
      #   person.pets.many? #=> true
      #
      # You can also pass a block to define criteria. The
      # behavior is the same, it returns true if the collection
      # based on the criteria has more than one record.
      #
      #   person.pets
      #   # => [
      #   #      #<Pet name: "Gorby", group: "cats">,
      #   #      #<Pet name: "Puff", group: "cats">,
      #   #      #<Pet name: "Snoop", group: "dogs">
      #   #    ]
      #
      #   person.pets.many? do |pet|
      #     pet.group == 'dogs'
      #   end
      #   # => false
      #
      #   person.pets.many? do |pet|
      #     pet.group == 'cats'
      #   end
      #   # => true
      def many?(&block)
        @association.many?(&block)
      end

      # Returns +true+ if the given object is present in the collection.
      #
      #   class Person < ActiveFedora::Base
      #     has_many :pets
      #   end
      #
      #   person.pets # => [#<Pet id: 20, name: "Snoop">]
      #
      #   person.pets.include?(Pet.find(20)) # => true
      #   person.pets.include?(Pet.find(21)) # => false
      def include?(record)
        @association.include?(record)
      end

      alias new build

      def proxy_association
        @association
      end

      # @return [Relation] object for the records in this association
      def scope
        @association.scope
      end
      alias spawn scope

      def to_ary
        load_target.dup
      end
      alias to_a to_ary

      def <<(*records)
        proxy_association.concat(records) && self
      end
      alias push <<

      def clear
        delete_all
        self
      end

      def reload
        proxy_association.reload
        self
      end
    end
  end
end
