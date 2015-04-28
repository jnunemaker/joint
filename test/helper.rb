require 'bundler/setup'
Bundler.setup(:default, 'test', 'development')

require 'tempfile'
require 'mongo_mapper'

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/mini_test'

require File.expand_path(File.dirname(__FILE__) + '/../lib/joint')

MongoMapper.database = "joint_test"

class Minitest::Test
  def setup
    MongoMapper.database.collections.each { |coll| coll.remove unless coll.name =~ /^system/ }
  end

  def assert_difference(expression, difference = 1, message = nil, &block)
    b      = block.send(:binding)
    exps   = Array.wrap(expression)
    before = exps.map { |e| eval(e, b) }
    yield
    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      after = eval(e, b)
      assert_equal(before[i] + difference, after, error)
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

class Asset
  include MongoMapper::Document
  plugin Joint

  key :title, String
  attachment :image
  attachment :file
  has_many :embedded_assets
end

class EmbeddedAsset
  include MongoMapper::EmbeddedDocument
  plugin Joint

  key :title, String
  attachment :image
  attachment :file
end

class BaseModel
  include MongoMapper::Document
  plugin Joint
  attachment :file
end

class Image < BaseModel; attachment :image end
class Video < BaseModel; attachment :video end

module JointTestHelpers
  def all_files
    [@file, @image, @image2, @test1, @test2]
  end

  def rewind_files
    all_files.each { |file| file.rewind }
  end

  def open_file(name)
    f = File.open(File.join(File.dirname(__FILE__), 'fixtures', name), 'r')
    f.binmode
    f
  end

  def grid
    @grid ||= Mongo::Grid.new(MongoMapper.database)
  end

  def key_names
    [:id, :name, :type, :size]
  end
end
