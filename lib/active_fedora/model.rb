SOLR_DOCUMENT_ID = "id" unless defined?(SOLR_DOCUMENT_ID)

module ActiveFedora
  # = ActiveFedora
  # This module mixes various methods into the including class,
  # much in the way ActiveRecord does.  
  module Model 
    module ClassMethods
      # Takes a Fedora URI for a cModel, and returns a 
      # corresponding Model if available
      # This method should reverse ClassMethods#to_class_uri
      # @return [Class, False] the class of the model or false, if it does not exist
      def from_class_uri(model_value)

        if class_exists?(model_value)
          ActiveFedora.class_from_string(model_value)
        else
          rc = @@uris[model_value]
          return rc if rc
          ActiveFedora::Base.logger.warn "'#{model_value}' is not a real class" if ActiveFedora::Base.logger
          return nil
        end
      end

      def subclass(uri=nil)
        rc = Class.new(self)
        rc.interim_uri = uri
        rc
      end
      protected
      def inherited(subclass)
        super
        subclass.uri= self.interim_uri
        self.interim_uri = nil # only use once
        @@uris[subclass.uri] = subclass if subclass.uri
        unless subclass.name.nil? # ignore the interim classes
          parts = subclass.name.split('::')
          rcvr = parts[0...-1].join('::')
          if rcvr.eql? ''
            rcvr = Object
          else
            rcvr = rcvr.constantize
          end
          metaclass = class << rcvr; self; end
          metaclass.send(:define_method, parts.last, Proc.new{|uri| subclass.subclass(uri) })
        end
      end
      def interim_uri
        @interim_uri
      end
      def interim_uri=(uri)
        @interim_uri = uri
        @interim_uri.freeze
      end
      def uri
        @uri
      end
      def uri=(uri)
        @uri = uri
        @uri.freeze
      end

      private 
      @@uris       = {}

      def class_exists?(class_name)
        return false if class_name.empty?
        klass = class_name.constantize
        return klass.is_a?(Class) || @@uris[klass]
      rescue NameError
        return false
      end
    end
    extend ClassMethods
  end
end
