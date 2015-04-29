require 'helper'

describe "FileHelpers" do
  include JointTestHelpers

  before do
    @image = open_file('mr_t.jpg')
  end

  after do
    @image.close
  end

  describe ".name" do
    it "return original_filename" do
      def @image.original_filename
        'frank.jpg'
      end
      Joint::FileHelpers.name(@image).must_equal 'frank.jpg'
    end

    it "fall back to File.basename" do
      Joint::FileHelpers.name(@image).must_equal 'mr_t.jpg'
    end
  end

  describe ".size" do
    it "return size" do
      def @image.size
        25
      end
      Joint::FileHelpers.size(@image).must_equal 25
    end

    it "fall back to File.size" do
      Joint::FileHelpers.size(@image).must_equal 13661
    end
  end

  describe ".type" do
    it "return type if Joint::IO instance" do
      file = Joint::IO.new(:type => 'image/jpeg')
      Joint::FileHelpers.type(@image).must_equal 'image/jpeg'
    end

    it "fall back to Wand" do
      Joint::FileHelpers.type(@image).must_equal 'image/jpeg'
    end
  end

end
