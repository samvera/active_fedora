module ActiveFedora

  # Abstract class for attributes that are delegated to a serialized representation such as a NonRDFSource
  # 
  # @abstract
  # @attr [String] delegate_target
  # @attr [String] at
  # @attr [String] target_class

  class StreamAttribute < DelegatedAttribute

    attr_accessor :delegate_target, :at, :target_class

    # @param [Symbol] field the field to find or create
    # @param [Hash] args 
    # @option args [String] :delegate_target the path to the delegate
    # @option args [Class] :klass the class to create
    # @option args [true,false] :multiple (false) true for multi-value fields
    # @option args [Array<Symbol>] :at path to a deep node 
    def initialize(field, args={})
      super
      self.delegate_target  = args.fetch(:delegate_target)
      self.target_class     = args.fetch(:klass)
      self.at               = args.fetch(:at, nil)
    end

    # Gives the primary solr name for a column. If there is more than one indexer on the field definition, it gives the first
    def primary_solr_name
      @datastream ||= target_class.new
      raise NoMethodError, "the file '#{target_class}' doesn't respond to 'primary_solr_name'" unless @datastream.respond_to?(:primary_solr_name)
      @datastream.primary_solr_name(field, delegate_target)
    end

    def type
      raise NoMethodError, "the file '#{target_class}' doesn't respond to 'type'" unless target_class.respond_to?(:type)
      target_class.type(field)
    end

    private

      def file_for_attribute(obj, delegate_target)
        obj.attached_files[delegate_target] || raise(ArgumentError, "Undefined file: `#{delegate_target}' in property #{field}")
      end

  end
end
