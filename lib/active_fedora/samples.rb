# require all of the files in the samples directory
module Hydra;end
Dir[File.join(File.dirname(__FILE__), "samples", "*.rb")].each {|f| require f}