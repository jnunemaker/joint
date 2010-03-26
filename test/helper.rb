require 'test/unit'
require 'tempfile'
require 'pp'

require 'mongo_mapper'

require File.expand_path(File.dirname(__FILE__) + '/../lib/joint')

MongoMapper.database = "testing"

class Test::Unit::TestCase
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end