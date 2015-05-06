module ActiveFedora
  class FileRelation < Relation
    def load_from_fedora(id, _)
      klass.new(klass.id_to_uri(id))
    end
  end
end
