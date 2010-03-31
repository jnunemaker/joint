require 'tempfile'
require 'pp'
require 'mongo_mapper'
require 'shoulda'
require 'matchy'
require 'mocha'

require File.expand_path(File.dirname(__FILE__) + '/../lib/joint')

MongoMapper.database = "testing"

class Test::Unit::TestCase
  def assert_difference(expression, difference = 1, message = nil, &block)
    b      = block.send(:binding)
    exps   = Array.wrap(expression)
    before = exps.map { |e| eval(e, b) }
    yield
    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, eval(e, b), error)
    end
  end

  def assert_no_difference(expression, message = nil, &block)
    assert_difference(expression, 0, message, &block)
  end

  def assert_grid_difference(difference=1, &block)
    assert_difference("MongoMapper.database['fs.files'].find().count", difference, &block)
  end

  def assert_no_grid_difference(&block)
    assert_grid_difference(0, &block)
  end
end