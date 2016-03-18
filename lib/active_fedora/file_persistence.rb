module ActiveFedora
  module FilePersistence
    extend ActiveSupport::Concern

    include ActiveFedora::Persistence

    private

      def _create_record(_options = {})
        return false if content.nil?
        ldp_source.content = content
        ldp_source.create do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end

      def _update_record(_options = {})
        return true unless content_changed?
        ldp_source.content = content
        ldp_source.update do |req|
          req.headers.merge!(ldp_headers)
        end
        refresh
      end
  end
end
