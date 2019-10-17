module ActiveFedora
  class DirectContainer < Container
    def build_ldp_resource(id)
      DirectContainerResource.new(ActiveFedora.fedora.connection, self.class.id_to_uri(id))
    end
  end
end
