module ActiveFedora
  module Orders
    class CollectionProxy < ActiveFedora::Associations::CollectionProxy
      attr_reader :association
      delegate :append_target, :insert_target_at, :insert_target_id_at, :delete_at, to: :association
    end
  end
end
