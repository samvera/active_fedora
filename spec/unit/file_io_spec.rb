# frozen_string_literal: true
require 'spec_helper'

describe ActiveFedora::FileIO do
  # 300,000 byte test string
  let(:test_file) do
    (0..300_000).reduce('') do |s, c|
      output = s.dup
      output << (c % 256).chr
      output
    end
  end
  let(:file_contents) { test_file }
  let(:new_fedora_file) { ActiveFedora::File.new }
  let(:fedora_file) do
    new_fedora_file.tap do |file|
      file.content = file_contents
      file.save
    end
  end
  let(:io) { described_class.new(fedora_file) }

  describe "#read" do
    it "reads the entire file when called without parameters" do
      expect(io.read).to eql(file_contents)
    end

    it "returns nil at end of file when requested with length" do
      io.read
      expect(io.read(10)).to be_nil
    end

    it "returns only requested amount of bytes" do
      content_slice_one = file_contents[0..4]
      request_one = io.read(5)
      expect(request_one).to eql(content_slice_one)

      content_slice_two = file_contents[5..9]
      request_two = io.read(5)
      expect(request_two).to eql(content_slice_two)

      content_slice_three = file_contents[10..99]
      request_three = io.read(90)
      expect(request_three).to eql(content_slice_three)
    end

    it "returns an empty string if 0 bytes is requested" do
      expect(io.read(0)).to eql('')
    end

    it "raises an error with negative length parameter" do
      expect { io.read(-1) }.to raise_error(ArgumentError)
    end

    it "returns ASCII-8BIT strings" do
      expect(io.read(10).encoding.to_s).to eql("ASCII-8BIT")
      expect(io.read.encoding.to_s).to eql("ASCII-8BIT")
    end

    it "can take a buffer parameter" do
      buffer = String.new
      output = io.read(100, buffer)
      expect(output).to eql(file_contents[0..99])
      expect(buffer).to eql(file_contents[0..99])
      # IO.read will clear the buffer if it's not empty
      expect(io.read(100, buffer)).to eql(file_contents[100..199])
      expect(buffer).to eql(file_contents[100..199])
    end

    context "with empty file" do
      let(:file_contents) { '' }
      it "returns an empty string when called without parameters" do
        expect(io.read).to eql('')
      end

      it "returns nil when called with length parameter" do
        expect(io.read(10)).to be_nil
      end
    end

    context "edge cases" do
      let(:stream) {
        instance_double(ActiveFedora::File::Streaming::FileBody).tap do |stream|
          allow(stream).to receive(:each) do |&block|
            ['abcd', 'efghijkl', 'mnopqrst', 'uvwxy', 'z'].each(&block)
          end
        end
      }
      before {
        allow(fedora_file).to receive(:stream).and_return(stream)
      }
      let(:file_contents) { 'abcdefghijklmnopqrstuvwxyz' }
      xit "are handled correctly" do
        expect(io.read(4)).to eql('abcd')
        expect(io.read(7)).to eql('efghijk')
        expect(io.read(9)).to eql('lmnopqrst')
        expect(io.read(6)).to eql('uvwxyz')
        expect(io.read(4)).to be_nil
      end
    end
  end

  describe "#pos" do
    it "returns current position" do
      expect(io.pos).to eq(0)
      io.read(5)
      expect(io.pos).to eq(5)
      io.read(100_000)
      expect(io.pos).to eq(100_005)
      io.read
      expect(io.pos).to eq(file_contents.length)
      io.rewind
      expect(io.pos).to eq(0)
    end
  end

  describe "#rewind" do
    it "restarts the stream" do
      io.read(10)
      io.rewind
      expect(io.read(10)).to eql(file_contents[0..9])
    end
  end

  describe "#close" do
    it "closes the stream" do
      io.read(10)
      io.close
      expect { io.read(10) } .to raise_error(IOError)
    end
  end

  describe "#binmode" do
    it "responds to binmode" do
      expect { io.binmode } .not_to raise_error
    end
  end

  describe "#binmode?" do
    it "returns true" do
      expect(io.binmode?).to be(true)
    end
  end

  describe "working with IO.copy_stream" do
    let(:output_stream) { StringIO.new .tap(&:binmode) }
    it "copies the stream" do
      IO.copy_stream(io, output_stream)
      expect(output_stream.string).to eql(file_contents)
    end
  end
end
