module ActiveFedora
  class InitializingConnection < Delegator
    attr_reader :connection, :root_resource_path

    def initialize(connection, root_resource_path)
      super(connection)
      @connection = connection
      @root_resource_path = root_resource_path
      @initialized = false
    end

    def __getobj__
      @connection
    end

    def __setobj__(connection)
      @connection = connection
    end

    def head(*)
      init_base_path
      super
    end

    def get(*)
      init_base_path
      super
    end

    def delete(*)
      init_base_path
      super
    end

    def post(*)
      init_base_path
      super
    end

    def put(*)
      init_base_path
      super
    end

    def patch(*)
      init_base_path
      super
    end

    private

      # Call this to create a Container Resource to act as the base path for this connection
      def init_base_path
        return if @initialized

        connection.head(root_resource_path)
        ActiveFedora::Base.logger.info "Attempted to init base path `#{root_resource_path}`, but it already exists"
        @initialized = true
        false
      rescue Ldp::NotFound
        @initialized = connection.put(root_resource_path, '').success?
      end
  end
end
