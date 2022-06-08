# frozen_string_literal: true
module ActiveFedora
  class NullLogger < Logger
    # rubocop:disable Lint/MissingSuper
    def initialize(*); end
    # rubocop:enable Lint/MissingSuper

    # allows all the usual logger method calls (warn, info, error, etc.)
    def add(*); end

    # In the NullLogger there are no levels, so none of these should be true.
    [:debug?, :info?, :warn?, :error?, :fatal?].each do |method_name|
      define_method(method_name) { false }
    end
  end
end
