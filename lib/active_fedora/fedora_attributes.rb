module ActiveFedora
  module FedoraAttributes

    delegate :state=, :label=, to: :inner_object

    #return the pid of the Fedora Object
    # if there is no fedora object (loaded from solr) get the instance var
    # TODO make inner_object a proxy that can hold the pid
    def pid
       @inner_object.pid
    end

    def id   ### Needed for the nested form helper
      self.pid
    end

    #return the owner id
    def owner_id
      Array(@inner_object.ownerId).first
    end
    
    def owner_id=(owner_id)
      @inner_object.ownerId=(owner_id)
    end

    def label
      Array(@inner_object.label).first
    end

    def state
      Array(@inner_object.state).first
    end

    #return the create_date of the inner object (unless it's a new object)
    def create_date
      @inner_object.new_record? ?  Time.now : Array(@inner_object.createdDate).first
    end

    #return the modification date of the inner object (unless it's a new object)
    def modified_date
      @inner_object.new_record? ? Time.now : Array(@inner_object.lastModifiedDate).first
    end

  end
end
