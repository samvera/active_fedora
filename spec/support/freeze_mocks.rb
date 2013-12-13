# Don't raise errors if the object is frozen.
# Work around a bug in rspec-mocks 2.14.4
# https://github.com/rspec/rspec-mocks/issues/494
RSpec::Mocks::MethodDouble.class_eval do
  alias_method :original_restore_original_method, :restore_original_method
  def restore_original_method
      original_restore_original_method
  rescue => e
    raise e unless object_singleton_class.frozen?
    Kernel.warn "Unable to remove stub method #{@method_name} because the object was frozen"
  end
end
