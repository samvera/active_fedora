# This is the parent class of DirectlyContainsAssociation and IndirectlyContainsAssociation
module ActiveFedora
  module Associations
    class ContainsAssociation < CollectionAssociation #:nodoc:

      def reader
        @records ||= ContainerProxy.new(self)
      end

      protected

        def count_records
          load_target.size
        end

        def uri
          raise "Can't get uri. Owner isn't saved" if @owner.new_record?
          "#{@owner.uri}/#{@reflection.name}"
        end
    end
  end
end

