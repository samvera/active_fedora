# This is the parent class of BasicContainsAssociation, DirectlyContainsAssociation and IndirectlyContainsAssociation
module ActiveFedora
  module Associations
    class ContainsAssociation < CollectionAssociation #:nodoc:
      def insert_record(record, force = true, validate = true)
        if force
          record.save!
        else
          record.save(validate: validate)
        end
      end

      def reader
        @records ||= ContainerProxy.new(self)
      end

      def include?(other)
        if loaded?
          target.include?(other)
        elsif container_predicate = options[:has_member_relation]
          owner.resource.query(predicate: container_predicate, object: ::RDF::URI(other.uri)).present?
        else # is_member_of_relation
          # This will force a load, so it's slowest and the least preferable option
          target.include?(other)
        end
      end

      protected

        def count_records
          load_target.size
        end

        def uri
          raise "Can't get uri. Owner isn't saved" if @owner.new_record?
          "#{@owner.uri}/#{@reflection.name}"
        end

      private

        def delete_records(records, method)
          if method == :destroy
            records.each(&:destroy)
          else
            records.each(&:delete)
          end
        end
    end
  end
end
