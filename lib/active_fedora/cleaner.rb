module ActiveFedora
  module Cleaner
    def self.clean!
      cleanout_fedora
      reinitialize_repo
      cleanout_solr
    end

    def self.cleanout_fedora
      delete_root_resource
      delete_tombstone
    rescue Ldp::HttpError => exception
      log "#cleanout_fedora in spec_helper.rb raised #{exception}"
    end

    def self.delete_root_resource
      connection.delete(root_resource_path)
    rescue Ldp::Gone
    end

    def self.delete_tombstone
      connection.delete(tombstone_path)
    end

    def self.tombstone_path
      root_resource_path + "/fcr:tombstone"
    end

    def self.root_resource_path
      ActiveFedora.fedora.root_resource_path
    end

    def self.connection
      ActiveFedora.fedora.connection
    end

    def self.solr_connection
      ActiveFedora::SolrService.instance && ActiveFedora::SolrService.instance.conn
    end

    def self.cleanout_solr
      restore_spec_configuration if solr_connection.nil?
      solr_connection.delete_by_query('*:*', params: { 'softCommit' => true })
    end

    def self.reinitialize_repo
      ActiveFedora::Fedora.reset!
    end

    def self.log(message)
      ActiveFedora::Base.logger.debug message
    end
  end
end
