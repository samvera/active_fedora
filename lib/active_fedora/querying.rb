module ActiveFedora
  module Querying
    delegate :find, :first, :exists?, :where, :limit, :offset, :order, :delete_all,
             :destroy_all, :count, :last, :search_with_conditions, :search_in_batches, :search_by_id, :find_each, to: :all

    def self.extended(base)
      base.class_attribute :solr_query_handler
      base.solr_query_handler = 'standard'
    end

    def default_sort_params
      [ActiveFedora.index_field_mapper.solr_name('system_create', :stored_sortable, type: :date) +
        ' asc']
    end
  end
end
