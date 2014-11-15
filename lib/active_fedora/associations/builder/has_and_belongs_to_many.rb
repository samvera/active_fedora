module ActiveFedora::Associations::Builder
  class HasAndBelongsToMany < CollectionAssociation #:nodoc:
    self.macro = :has_and_belongs_to_many

    self.valid_options += [:inverse_of, :solr_page_size]

    def validate_options
      super
      if !options[:predicate]
        raise "You must specify a predicate for #{name}"
      elsif !options[:predicate].kind_of?(RDF::URI)
        raise ArgumentError, "Predicate must be a kind of RDF::URI"
      end
    end

    def build
      reflection = super
      define_destroy_hook
      reflection
    end

    private

      def define_destroy_hook
        # Don't use a before_destroy callback since users' before_destroy
        # callbacks will be executed after the association is wiped out.
        # TODO Update to destroy_associations
        name = self.name
        model.send(:include, Module.new {
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def destroy          # def destroy
              #{name}.clear      #   posts.clear
              super              #   super
            end                  # end
          RUBY
        })
      end

  end
end
