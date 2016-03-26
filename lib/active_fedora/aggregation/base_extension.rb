module ActiveFedora::Aggregation
  module BaseExtension
    def ordered_by
      ordered_by_ids.lazy.map { |x| ActiveFedora::Base.find(x) }
    end

    private

      def ordered_by_ids
        if id.present?
          ActiveFedora::SolrService.query("{!join from=proxy_in_ssi to=id}ordered_targets_ssim:#{id}").map { |x| x["id"] }
        else
          []
        end
      end
  end
end
