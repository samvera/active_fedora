module ActiveFedora
  class NullLogger < Logger
    def initialize(*)
    end

    # allows all the usual logger method calls (warn, info, error, etc.)
    def add(*)
    end
  end
end
