module ActiveFedora
  module FedoraAttributes

    delegate :state=, :label=, to: :inner_object

    def pid
      # TODO deprecate this
      id
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

    # def state
    #   Array(@inner_object.state).first
    # end

    #return the create_date of the inner object (unless it's a new object)
    # def create_date
    #   new_record? ?  Time.now : Array(@inner_object.createdDate).first
    # end

    #return the modification date of the inner object (unless it's a new object)
    # def modified_date
    #   new_record? ? Time.now : Array(@inner_object.lastModifiedDate).first
    # end

  end
end
