module ActiveFedora
  # in ./spec/spec_helper.rb
  # ``` require 'active_fedora/rspec_matchers' ```
  module RspecMatchers
  end
end
pattern = Dir.glob(File.join(File.dirname(__FILE__), 'rspec_matchers/*_matcher.rb'))
pattern.each { |f| require f }
