require 'tempfile'
require 'pp'
require 'mongo_mapper'
require 'shoulda'
require 'matchy'

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
end