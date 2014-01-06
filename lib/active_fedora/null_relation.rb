module ActiveFedora
  module NullRelation # :nodoc:
    def exists?(_id = false)
      false
    end
  end
end
