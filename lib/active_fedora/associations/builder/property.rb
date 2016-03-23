module ActiveFedora::Associations::Builder
  class Property < Association
    def self.macro
      :rdf
    end

    def self.valid_options(options)
      super
    end

    def self.better_name(name)
      :"#{name.to_s.singularize}_ids"
    end
  end
end
