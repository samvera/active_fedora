module ActiveFedora
  # = Active Fedora \Named \Scopes
  module Scoping
    module Named
      extend ActiveSupport::Concern

      module ClassMethods
        # Returns an <tt>ActiveFedora::Relation</tt> scope object.
        #
        #   posts = Post.all
        #   posts.size # Fires "select count(*) from  posts" and returns the count
        #   posts.each {|p| puts p.name } # Fires "select * from posts" and loads post objects
        #
        #   fruits = Fruit.all
        #   fruits = fruits.where(color: 'red') if options[:red_only]
        #   fruits = fruits.limit(10) if limited?
        #
        # You can define a scope that applies to all finders using
        # <tt>ActiveRecord::Base.default_scope</tt>.
        def all
          if current_scope
            current_scope.clone
          else
            default_scoped
          end
        end

        def default_scoped
          scope = build_default_scope

          if scope
            relation.spawn.merge!(scope)
          else
            relation
          end
        end
      end
    end
  end
end
