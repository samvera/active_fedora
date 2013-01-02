module ActiveFedora
  module Querying
    delegate :first, :where, :limit, :order, :to=>:relation
  end
end
