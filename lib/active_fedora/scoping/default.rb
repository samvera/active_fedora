module ActiveFedora
  module Scoping
    module Default
      extend ActiveSupport::Concern

      module ClassMethods
        # Returns a scope for the model without the +default_scope+.
        #
        #   class Post < ActiveRecord::Base
        #     def self.default_scope
        #       where published: true
        #     end
        #   end
        #
        #   Post.all          # Fires "SELECT * FROM posts WHERE published = true"
        #   Post.unscoped.all # Fires "SELECT * FROM posts"
        #
        # This method also accepts a block. All queries inside the block will
        # not use the +default_scope+:
        #
        #   Post.unscoped {
        #     Post.limit(10) # Fires "SELECT * FROM posts LIMIT 10"
        #   }
        #
        # It is recommended that you use the block form of unscoped because
        # chaining unscoped with +scope+ does not work. Assuming that
        # +published+ is a +scope+, the following two statements
        # are equal: the +default_scope+ is applied on both.
        #
        #   Post.unscoped.published
        #   Post.published
        def unscoped
          block_given? ? relation.scoping { yield } : relation
        end
      end
    end
  end
end
