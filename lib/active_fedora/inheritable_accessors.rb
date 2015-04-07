# Similar to ActiveSupport.class_attribute but with a setter that doesn't use the #{name}= syntax
# This preserves backward compatibility with the API in ActiveTriples

module ActiveFedora
  module InheritableAccessors
    extend ActiveSupport::Concern
    module ClassMethods
      def define_inheritable_accessor(*names)
        names.each do |name|
          define_accessor(name, nil)
        end
      end

      private
        def define_accessor(name, val)
          singleton_class.class_eval do
            remove_possible_method(name)
            define_method(name) do |uri = nil|
              define_accessor(name, uri) if uri
              val
            end
          end
        end
    end
  end
end
