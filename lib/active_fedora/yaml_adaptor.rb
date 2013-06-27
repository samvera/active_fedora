begin
  require 'psych'
  YAMLAdaptor = Psych
rescue LoadError
  $stderr.puts "*"*80
  $stderr.puts "WARNING: Unable to load Psych, falling back to YAML for parser."
  $stderr.puts "    YAML will be removed in ActiveFedora 7.0.0."
  $stderr.puts "    YAMLAdaptor will be removed in ActiveFedora 7.0.0, and replaced with Psych"
  $stderr.puts "*"*80
  require 'yaml'
  YAMLAdaptor = YAML
end
