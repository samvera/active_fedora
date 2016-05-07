module ActiveFedora::Associations::Builder
  class BasicContains < CollectionAssociation #:nodoc:
    def self.macro
      :is_a_container
    end
  end
end
