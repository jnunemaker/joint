# encoding: UTF-8
require File.expand_path('../lib/joint/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "joint"
  s.summary     = %Q{MongoMapper and GridFS joined in file upload love.}
  s.description = %Q{MongoMapper and GridFS joined in file upload love.}
  s.email       = "nunemaker@gmail.com"
  s.homepage    = "http://github.com/jnunemaker/joint"
  s.require_path = 'lib'
  s.authors     = ["John Nunemaker"]
  s.version     = Joint::Version
  s.files       = Dir.glob("{lib,test}/**/*") + %w[LICENSE README.rdoc]
  s.test_files  = Dir.glob("test/**/*")

  s.add_dependency 'wand', '~> 0.3'
  s.add_dependency 'mime-types'
  s.add_dependency 'mongo_mapper', '~> 0.8.6'

  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'jnunemaker-matchy'
end