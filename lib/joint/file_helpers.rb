module Joint
  module FileHelpers
    def self.name(file)
      if file.respond_to?(:original_filename)
        file.original_filename
      else
        File.basename(file.path)
      end
    end

    def self.size(file)
      if file.respond_to?(:size)
        file.size
      else
        File.size(file)
      end
    end

    def self.type(file)
      return file.type if file.is_a?(Joint::IO)
      Wand.wave(file.path, :original_filename => Joint::FileHelpers.name(file))
    end
  end
end