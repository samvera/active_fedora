module ActiveFedora::Associations::Builder
  class HasAndBelongsToMany < CollectionAssociation #:nodoc:
    self.macro = :has_and_belongs_to_many

    self.valid_options += [:inverse_of]

    def build
      reflection = super
      redefine_destroy
      reflection
    end

    private

      def redefine_destroy
        # Don't use a before_destroy callback since users' before_destroy
        # callbacks will be executed after the association is wiped out.
        name = self.name
        model.send(:include, Module.new {
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def destroy          # def destroy
              super              #   super
              #{name}.clear      #   posts.clear
            end                  # end
          RUBY
        })
      end

  end
end
