module ActiveFedora
  module Associations
    class BelongsToAssociation < AssociationProxy #:nodoc:
      private
        def find_target
          the_target = @owner.load_outbound_relationship(@reflection.options[:property]).first
          # the_target = @reflection.klass.send(:find,
          #   @owner[@reflection.primary_key_name],
          #   options
          # ) if @owner[@reflection.primary_key_name]
          the_target
        end


    end
  end
end
