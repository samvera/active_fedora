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
    # is computed directly through SQL and does not trigger by itself the
    # instantiation of the actual post records.
    class CollectionProxy < Relation # :nodoc:
      delegate :target, :load_target, :loaded?, :to => :@association

      delegate :select, :find, :first, :last,
               :build, :create, :create!, :count,
               :concat, :delete_all, :destroy_all, :delete, :destroy, :uniq,
               :sum, :size, :length, :empty?,
               :any?, :many?, :include?,
               :to => :@association

      def initialize(association)
        @association = association
        super association.klass
        merge! association.scope
      end

      alias_method :new, :build

      def proxy_association
        @association
      end

      def to_ary
        load_target.dup
      end
      alias_method :to_a, :to_ary

      def <<(*records)
        proxy_association.concat(records) && self
      end
      alias_method :push, :<<

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
