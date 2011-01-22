require 'helper'

class IOTest < Test::Unit::TestCase
  context "#initialize" do
    should "set attributes from hash" do
      Joint::IO.new(:name => 'foo').name.should == 'foo'
    end
  end

  should "default type to plain text" do
    Joint::IO.new.type.should == 'plain/text'
  end

  should "default size to content size" do
    content = 'This is my content'
    Joint::IO.new(:content => content).size.should == content.size
  end

  should "alias path to name" do
    Joint::IO.new(:name => 'foo').path.should == 'foo'
  end

  context "#read" do
    should "return content" do
      Joint::IO.new(:content => 'Testing').read.should == 'Testing'
    end
  end
end