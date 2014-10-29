module ActiveFedora
  module Cleaner
    def self.clean!
      cleanout_fedora
      reinitialize_repo
      cleanout_solr
    end

    def self.cleanout_fedora
      tombstone_path = ActiveFedora.fedora.base_path.sub('/', '') + "/fcr:tombstone"
      begin
        ActiveFedora.fedora.connection.delete(ActiveFedora.fedora.base_path.sub('/', ''))
        ActiveFedora.fedora.connection.delete(tombstone_path)
      rescue Ldp::HttpError => exception

        ActiveFedora::Base.logger.debug "#cleanout_fedora in spec_helper.rb raised #{exception}"
      end
    end

    def self.cleanout_solr
      restore_spec_configuration if ActiveFedora::SolrService.instance.nil? || ActiveFedora::SolrService.instance.conn.nil?
      ActiveFedora::SolrService.instance.conn.delete_by_query('*:*', params: {'softCommit' => true})
    end

    def self.reinitialize_repo
      begin
        ActiveFedora.fedora.connection.put(ActiveFedora.fedora.base_path.sub('/', ''),"")
      rescue Ldp::HttpError => exception
        ActiveFedora::Base.logger.debug "#reinitialize_repo in spec_helper.rb raised #{exception}"
      end
    end
  end
end
