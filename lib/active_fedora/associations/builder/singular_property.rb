# frozen_string_literal: true
module ActiveFedora::Associations::Builder
  class SingularProperty < Property
    def self.macro
      :singular_rdf
    end

    def self.better_name(name)
      :"#{name}_id"
    end
  end
end
