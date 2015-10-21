module ActiveFedora
  class Checksum

    attr_reader :uri, :value, :algorithm

    def initialize(file)
      @uri = file.digest.first
      if @uri
        @algorithm, @value = @uri.path.split(":")
        @algorithm.upcase!
      end
    end

  end
end
