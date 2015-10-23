require 'active_fedora/relation/merger'

module ActiveFedora
  module SpawnMethods
    # This is overridden by Associations::CollectionProxy
    def spawn #:nodoc:
      clone
    end

    # Merges in the conditions from <tt>other</tt>, if <tt>other</tt> is an <tt>ActiveRecord::Relation</tt>.
    # Returns an array representing the intersection of the resulting records with <tt>other</tt>, if <tt>other</tt> is an array.
    #   Post.where(published: true).joins(:comments).merge( Comment.where(spam: false) )
    #   # Performs a single join query with both where conditions.
    #
    #   recent_posts = Post.order('created_at DESC').first(5)
    #   Post.where(published: true).merge(recent_posts)
    #   # Returns the intersection of all published posts with the 5 most recently created posts.
    #   # (This is just an example. You'd probably want to do this with a single query!)
    #
    # Procs will be evaluated by merge:
    #
    #   Post.where(published: true).merge(-> { joins(:comments) })
    #   # => Post.where(published: true).joins(:comments)
    #
    # This is mainly intended for sharing common conditions between multiple associations.
    def merge(other)
      if other.is_a?(Array)
        to_a & other
      elsif other
        spawn.merge!(other)
      else
        self
      end
    end

    def merge!(other) # :nodoc:
      if !other.is_a?(Relation) && other.respond_to?(:to_proc)
        instance_exec(&other)
      else
        klass = other.is_a?(Hash) ? Relation::HashMerger : Relation::Merger
        klass.new(self, other).merge
      end
    end
  end
end
