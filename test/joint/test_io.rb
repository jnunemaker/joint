require 'helper'

describe IO do

  describe "#initialize" do
    it "set attributes from hash" do
      Joint::IO.new(:name => 'foo').name.must_equal 'foo'
    end
  end

  it "default type to plain text" do
    Joint::IO.new.type.must_equal 'plain/text'
  end

  it "default size to content size" do
    content = 'This is my content'
    Joint::IO.new(:content => content).size.must_equal content.size
  end

  it "alias path to name" do
    Joint::IO.new(:name => 'foo').path.must_equal 'foo'
  end

  describe "#read" do
    it "return content" do
      Joint::IO.new(:content => 'Testing').read.must_equal 'Testing'
    end
  end
  
  describe "#rewind" do
    it "rewinds the io to position 0" do
      io = Joint::IO.new(:content => 'Testing')
      io.read.must_equal 'Testing'
      io.read.must_equal ''
      io.rewind
      io.read.must_equal 'Testing'
    end
  end
  
end
