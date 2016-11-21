require 'rubydora'

module ActiveFedora
  class RubydoraConnection
    
    attr_accessor :options, :connection

    def initialize(params={})
      params = params.dup
      self.options = params
      connect
    end

    def connect(force=false)
      return unless @connection.nil? or force
      @connection = Rubydora.connect options

      Rubydora::Transaction.after_rollback do |options|
        begin
          case options[:method]
            when :ingest
              solr = ActiveFedora::SolrService.instance.conn
              solr.delete_by_id(options[:pid])
              solr.commit
            else
              ActiveFedora::Base.find(options[:pid]).update_index
          end
        rescue
          # no-op
        end

      end
    end
  end
end
