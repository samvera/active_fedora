module ActiveFedora::Associations
  ##
  # A composite object for an array of IDs. This abstracts away the fact that an
  # ID might be either a relative ID or a URI to a resource.
  class IDComposite
    attr_reader :ids, :id_translator
    include Enumerable
    # @param [Array<#to_s>] ids An array of ids or URIs to convert to IDs.
    # @param [#call] id_translator An object to handle the conversion of a URI
    #   to an ID.
    def initialize(ids, id_translator)
      @ids = ids
      @id_translator = id_translator
    end

    # @return [Array<relative_id>]
    def each
      ids.each do |id|
        yield convert(id)
      end
    end

    private

      def convert(id)
        if id.to_s.start_with?("http")
          id_translator.call(id)
        else
          id
        end
      end
  end
end
