module MediaShelfClassLevelInheritableAttributes
  def self.included(base)
    base.extend(MSClassMethods)
  end
  module MSClassMethods
    def ms_inheritable_attributes(*args)
      @ms_inheritable_attributes ||=[:ms_inheritable_attributes]
      @ms_inheritable_attributes+=args
      args.each do |arg|
        class_eval %(
          class <<self;attr_accessor :#{arg} end
        )
      end
      @ms_inheritable_attributes
    end
    def inherited(subclass)
      @ms_inheritable_attributes.each do |attrib|
        instance_var = "@#{attrib}"
        subclass.instance_variable_set(instance_var, instance_variable_get(instance_var))
      end
    end
  end
end
