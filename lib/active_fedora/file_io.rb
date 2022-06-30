# frozen_string_literal: true
module ActiveFedora
  ##
  # IO like object for reading Fedora files.
  # Use ActiveFedora::FileIO.new(fedora_file) to create one. You can then call
  # read on it or use it with IO.copy_stream and the like.
  #
  # @Note The stream will always be in binmode and return ASCII-8BIT content.
  class FileIO
    attr_reader :pos

    ##
    # @param [ActiveFedora::File] the file which is wrapped in this IO object.
    def initialize(fedora_file)
      @fedora_file = fedora_file
      @closed = false
      rewind # this initialises various variables
    end

    def size
      @fedora_file.size
    end

    alias length size

    def binmode
      # Do nothing, just return self. The stream is essentially always in binmode.
      self
    end

    def binmode?
      true
    end

    ##
    # Read bytes from the file. See IO.read for more information.
    # @param [Integer] the number of bytes to read. If nil or omitted, the
    #                  entire contents will be read.
    # @param [String] a string in which the contents are read. Can be omitted.
    # @return [String] the read bytes. If number of bytes to read was not
    #                  specified then always returns a String, possibly an empty
    #                  one. If number of bytes was specified then the returned
    #                  string will always be at least one byte long. If no bytes
    #                  are left in the file returns nil instead.
    def read(amount = nil, buf = nil)
      raise(IOError, "closed stream") if @closed

      buf ||= ''.dup.force_encoding("ASCII-8BIT")
      buf.clear

      if amount.nil?
        read_to_buf(nil, buf) # read the entire file, returns buf
      elsif amount.negative?
        raise(ArgumentError, "negative length #{amount} given")
      elsif amount.zero?
        ''
      else
        read_to_buf(amount, buf)
        # if amount was specified but we reached eof before reading anything
        # then we must return nil
        buf.empty? ? nil : buf
      end
    end

    ##
    # Rewinds the io object to the beginning. Read will return bytes from the
    # start of the file again.
    def rewind
      raise(IOError, "closed stream") if @closed
      @pos = 0
      @buffer = nil
      @stream_fiber = Fiber.new do
        @fedora_file.stream.each do |chunk|
          Fiber.yield chunk
        end
        @stream_fiber = nil
        # last value from Fiber is the return value of the block which should be nil
      end
      0
    end

    ##
    # Closes the file. No further action can be taken on the file.
    def close
      @closed = true
      @stream_fiber = nil
      nil
    end

    private

      def read_to_buf(amount, buf)
        buf << consume_buffer(amount.nil? ? nil : (amount - buf.length)) while (amount.nil? || buf.length < amount) && fill_buffer
        buf
      end

      def consume_buffer(count = nil)
        if count.nil? || count >= @buffer.length
          @pos += @buffer.length
          @buffer .tap do
            @buffer = nil
          end
        else
          @buffer.slice!(0, count) .tap do |slice|
            @pos += slice.length
          end
        end
      end

      def fill_buffer
        return true if @buffer.present?
        # Ruby Net library doesn't seem to like it if we modify the returned
        # chunk in any way, hence dup.
        @buffer = @stream_fiber.try(:resume).try(:dup)
        @buffer.try(:force_encoding, 'ASCII-8BIT')
        !@buffer.nil?
      end
  end
end
