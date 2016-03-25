module ActiveFedora::Aggregation
  module BaseExtension
    extend ActiveSupport::Concern

    def ordered_by
      ordered_by_ids.lazy.map{ |x| ActiveFedora::Base.find(x) }
    end

    private

      def ordered_by_ids
        if id.present?
          ActiveFedora::SolrService.query("{!join from=proxy_in_ssi to=id}ordered_targets_ssim:#{id}")
            .map{|x| x["id"]}
        else
          []
        end
      end

    module ClassMethods
      ##
      # Allows ordering of an association
      # @example
      #   class Image < ActiveFedora::Base
      #     contains :list_resource, class_name:
      #       "ActiveFedora::Aggregation::ListSource"
      #     orders :generic_files, through: :list_resource
      #   end
      def orders(name, options={})
        ActiveFedora::Orders::Builder.build(self, name, options)
      end

      ##
      # Convenience method for building an ordered aggregation.
      # @example
      #   class Image < ActiveFedora::Base
      #     ordered_aggregation :members, through: :list_source
      #   end
      def ordered_aggregation(name, options={})
        ActiveFedora::Orders::AggregationBuilder.build(self, name, options)
      end

      ##
      # Create an association filter on the class
      # @example
      #   class Image < ActiveFedora::Base
      #     aggregates :generic_files
      #     filters_association :generic_files, as: :large_files, condition: :big_file?
      #   end
      def filters_association(extending_from, options={})
        name = options.delete(:as)
        ActiveFedora::Filter::Builder.build(self, name, options.merge(extending_from: extending_from))
      end
    end
  end
end
