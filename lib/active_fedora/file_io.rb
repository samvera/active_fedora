
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

      new_out_buffer = String.new
      out_buffer = if buf.nil?
                     new_out_buffer
                   else
                     buf.force_encoding("ASCII-8BIT")
                     buf.clear
                   end
      fill_buffer unless @buffer
      amount = @buffer.length - @pos if amount.nil?

      raise(ArgumentError, "negative length #{amount} given") if amount.negative?

      if amount.zero?
        new_out_buffer
      else
        read_to_buffer(amount, out_buffer)
        # if amount was specified but we reached eof before reading anything
        # then we must return nil
        out_buffer.empty? ? nil : out_buffer
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
        # last value from Fiber is the return value of the block which should be nil
        @stream_fiber = nil
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

      def buffer_read?(length:, out_buffer:)
        return true if length.nil?

        out_buffer.length < length
      end

      def read_finished?
        @pos >= @buffer.length
      end

      def read_to_buffer(amount, stream)
        if !read_finished?
          bytes = read_bytes(amount)
          stream << bytes
        end

        stream
      end

      def read_bytes(count)
        total_slices = @buffer.slice(@pos..)
        slices = if count > total_slices.length - 1
                    total_slices
                  else
                    @buffer.slice(@pos..count - 1)
                  end

        @pos += count
        slices
      end

      def fill_buffer
        return true if @buffer.present?

        return false if @stream_fiber.nil?
        bytes = true
        while !@stream_fiber.nil? && @stream_fiber.alive? && !bytes.nil?
          # Ruby Net library doesn't seem to like it if we modify the returned
          # chunk in any way, hence dup.
          bytes = @stream_fiber.try(:resume).try(:dup)
          if !bytes.nil?
            @buffer = if @buffer.nil?
                        bytes
                      else
                        @buffer + bytes
                      end
          end
          break if @stream_fiber.nil? || bytes.nil?

        end

        @buffer = @buffer.try(:force_encoding, 'ASCII-8BIT')
        !@buffer.nil?
      end
  end
end
