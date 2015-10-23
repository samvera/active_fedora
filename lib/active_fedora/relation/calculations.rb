module ActiveFedora
  module Calculations
    # Get a count of the number of objects from solr
    # Takes :conditions as an argument
    def count(*args)
      return apply_finder_options(args.first).count if args.any?
      opts = {}
      opts[:rows] = limit_value if limit_value
      opts[:sort] = order_values if order_values

      calculate :count, where_values, opts
    end

    def calculate(_calculation, conditions, _opts = {})
      SolrService.query(create_query(conditions), raw: true, rows: 0).fetch('response'.freeze)['numFound'.freeze]
    end
  end
end
