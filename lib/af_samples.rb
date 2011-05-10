# require all of the files in the samples directory
Dir[File.join(File.dirname(__FILE__), "af_samples", "*.rb")].each {|f| require f}