module ActiveFedora
  module Associations
    extend ActiveSupport::Concern

    autoload :HasManyAssociation, 'active_fedora/associations/has_many_association'
    autoload :BelongsToAssociation, 'active_fedora/associations/belongs_to_association'

    autoload :AssociationCollection, 'active_fedora/associations/association_collection'
    autoload :AssociationProxy, 'active_fedora/associations/association_proxy'
    private 

      # Returns the specified association instance if it responds to :loaded?, nil otherwise.
      def association_instance_get(name)
        ivar = "@#{name}"
        if instance_variable_defined?(ivar)
          association = instance_variable_get(ivar)
          association if association.respond_to?(:loaded?)
        end
      end

      # Set the specified association instance.
      def association_instance_set(name, association)
        instance_variable_set("@#{name}", association)
      end

    

    module ClassMethods

      def has_many(association_id, options={})
        raise "You must specify a property name for #{name}" if !options[:property]
        has_relationship association_id.to_s, options[:property], :inbound => true
        reflection = create_has_many_reflection(association_id, options)
        collection_accessor_methods(reflection, HasManyAssociation)
      end

  
      def belongs_to(association_id, options = {})
        raise "You must specify a property name for #{name}" if !options[:property]
        has_relationship association_id.to_s, options[:property]
        reflection = create_belongs_to_reflection(association_id, options)

        association_accessor_methods(reflection, BelongsToAssociation)
          # association_constructor_method(:build,  reflection, BelongsToAssociation)
          # association_constructor_method(:create, reflection, BelongsToAssociation)
        #configure_dependency_for_belongs_to(reflection)
      end


      private 

        def create_has_many_reflection(association_id, options)
          create_reflection(:has_many, association_id, options, self)
        end

        def create_belongs_to_reflection(association_id, options)
          create_reflection(:belongs_to, association_id, options, self)
        end

        def association_accessor_methods(reflection, association_proxy_class)
          redefine_method(reflection.name) do |*params|
            force_reload = params.first unless params.empty?
            association = association_instance_get(reflection.name)

            if association.nil? || force_reload
              association = association_proxy_class.new(self, reflection)
              retval = force_reload ? reflection.klass.uncached { association.reload } : association.reload
              if retval.nil? and association_proxy_class == BelongsToAssociation
                association_instance_set(reflection.name, nil)
                return nil
              end
              association_instance_set(reflection.name, association)
            end

            association.target.nil? ? nil : association
          end

          redefine_method("loaded_#{reflection.name}?") do
            association = association_instance_get(reflection.name)
            association && association.loaded?
          end

          redefine_method("#{reflection.name}=") do |new_value|
            association = association_instance_get(reflection.name)

            if association.nil? || association.target != new_value
              association = association_proxy_class.new(self, reflection)
            end

            association.replace(new_value)
            association_instance_set(reflection.name, new_value.nil? ? nil : association)
          end

          redefine_method("set_#{reflection.name}_target") do |target|
            return if target.nil? and association_proxy_class == BelongsToAssociation
            association = association_proxy_class.new(self, reflection)
            association.target = target
            association_instance_set(reflection.name, association)
          end
        end


        def collection_reader_method(reflection, association_proxy_class)
          redefine_method(reflection.name) do |*params|
            
            force_reload = params.first unless params.empty?
            association = association_instance_get(reflection.name)
            unless association
              association = association_proxy_class.new(self, reflection)
              association_instance_set(reflection.name, association)
            end

            association.reload if force_reload

            association
          end

          redefine_method("#{reflection.name.to_s.singularize}_ids") do
              send(reflection.name).map { |r| r.pid }
          end

        end


        def collection_accessor_methods(reflection, association_proxy_class, writer = true)
          collection_reader_method(reflection, association_proxy_class)

          if writer
            redefine_method("#{reflection.name}=") do |new_value|
              # Loads proxy class instance (defined in collection_reader_method) if not already loaded
              association = send(reflection.name)
              association.replace(new_value)
              association
            end

            redefine_method("#{reflection.name.to_s.singularize}_ids=") do |new_value|
              pk_column = reflection.primary_key_column
              ids = (new_value || []).reject { |nid| nid.blank? }
              ids.map!{ |i| pk_column.type_cast(i) }
              send("#{reflection.name}=", reflection.klass.find(ids).index_by{ |r| r.id }.values_at(*ids))
            end
          end
        end
    end
  end
end
