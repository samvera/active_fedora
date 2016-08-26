def mock_yaml(hash, path)
  mock_file = instance_double(File, path.split("/")[-1])
  allow(File).to receive(:exist?).with(path).and_return(true)
  allow(File).to receive(:open).with(path).and_return(mock_file)
  allow(Psych).to receive(:load).and_return(hash)
end

def stub_rails(opts = {})
  Object.const_set("Rails", Class)
  Rails.send(:undef_method, :env) if Rails.respond_to?(:env)
  Rails.send(:undef_method, :root) if Rails.respond_to?(:root)
  opts.each { |k, v| Rails.send(:define_method, k) { return v } }
end

def unstub_rails
  Object.send(:remove_const, :Rails) if defined?(Rails)
end
