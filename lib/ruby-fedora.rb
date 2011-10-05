require 'rubygems'
gem 'xml-simple'
$LOAD_PATH.unshift File.dirname(__FILE__) unless
$LOAD_PATH.include?(File.dirname(__FILE__)) || $LOAD_PATH.include?(File.expand_path(File.dirname(__FILE__)))
module Fedora #:nodoc:
end
#extended to remove facets dep
class Hash 
  def rekey!
    self.each {|k,v| self[k.to_sym]=v; self.delete(k) unless self[k.to_sym]}
  end
end
