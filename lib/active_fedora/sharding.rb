module ActiveFedora
  module Sharding
    extend ActiveSupport::Concern

    included do
      class_attribute :fedora_connection
      self.fedora_connection = {}
    end

    module ClassMethods
      # Uses {#shard_index} to find or create the rubydora connection for this pid
      # @param [String] pid the identifier of the object to get the connection for
      # @return [Rubydora::Repository] The repository that the identifier exists in.
      def connection_for_pid(pid)
        idx = shard_index(pid)
        unless fedora_connection.has_key? idx
          if ActiveFedora.config.sharded?
            fedora_connection[idx] = RubydoraConnection.new(ActiveFedora.config.credentials[idx])
          else
            fedora_connection[idx] = RubydoraConnection.new(ActiveFedora.config.credentials)
          end
        end
        fedora_connection[idx].connection
      end

      # This is where your sharding strategy is implemented -- it's how we figure out which shard an object will be (or was) written to.
      # Given a pid, it decides which shard that pid will be written to (and thus retrieved from).
      # For a given pid, as long as your shard configuration remains the same it will always return the same value.
      # If you're not using sharding, this will always return 0, meaning use the first/only Fedora Repository in your configuration.
      # Default strategy runs a modulo of the md5 of the pid against the number of shards.
      # If you want to use a different sharding strategy, override this method.  Make sure that it will always return the same value for a given pid and shard configuration.
      #@return [Integer] the index of the shard this object is stored in
      def shard_index(pid)
        if ActiveFedora.config.sharded?
          Digest::MD5.hexdigest(pid).hex % ActiveFedora.config.credentials.length
        else
          0
        end
      end
      
      ### if you are doing sharding, override this method to do something other than use a sequence
      # @return [String] the unique pid for a new object
      def assign_pid(obj)
        args = {}
        args[:namespace] = obj.namespace if obj.namespace
        # TODO: This juggling of Fedora credentials & establishing connections should be handled by 
        # an establish_fedora_connection method,possibly wrap it all into a fedora_connection method - MZ 06-05-2012
        if ActiveFedora.config.sharded?
          credentials = ActiveFedora.config.credentials[0]
        else
          credentials = ActiveFedora.config.credentials
        end
        fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(credentials)
        fedora_connection[0].connection.mint(args)
      end
    end
  end
end
