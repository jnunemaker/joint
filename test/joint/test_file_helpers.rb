require 'helper'

class FileHelpersTest < Test::Unit::TestCase
  include JointTestHelpers

  def setup
    super
    @image  = open_file('mr_t.jpg')
  end

  def teardown
    @image.close
  end

  context ".name" do
    should "return original_filename" do
      def @image.original_filename
        'frank.jpg'
      end
      Joint::FileHelpers.name(@image).should == 'frank.jpg'
    end

    should "fall back to File.basename" do
      Joint::FileHelpers.name(@image).should == 'mr_t.jpg'
    end
  end

  context ".size" do
    should "return size" do
      def @image.size
        25
      end
      Joint::FileHelpers.size(@image).should == 25
    end

    should "fall back to File.size" do
      Joint::FileHelpers.size(@image).should == 13661
    end
  end

  context ".type" do
    should "return type if Joint::Io instance" do
      file = Joint::IO.new(:type => 'image/jpeg')
      Joint::FileHelpers.type(@image).should == 'image/jpeg'
    end

    should "fall back to Wand" do
      Joint::FileHelpers.type(@image).should == 'image/jpeg'
    end
  end

end