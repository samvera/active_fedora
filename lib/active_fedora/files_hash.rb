require 'forwardable'

module ActiveFedora
  class FilesHash
    extend Forwardable

    def_delegators :@hash, *(Hash.instance_methods(false))

    def initialize (&block)
      @hash = Hash.new &block
    end

    def freeze
      each_value do |file|
        file.freeze
      end
      @hash.freeze
      super
    end
  end
end
