# encoding: UTF-8
require File.expand_path('../lib/joint/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "jamieorc-joint"
  s.summary     = %Q{MongoMapper and GridFS joined in file upload love.}
  s.description = %Q{MongoMapper and GridFS joined in file upload love. Updates by Jamie for EmbeddedDocument.}
  s.email       = "jamieorc@gmail.com"
  s.homepage    = "http://github.com/jamieorc/joint"
  s.authors     = ["John Nunemaker", "Jamie Orchard-Hays"]
  s.version     = Joint::Version

  s.add_dependency 'wand', '~> 0.4'
  s.add_dependency 'mime-types'
  s.add_dependency 'mongo_mapper', '~> 0.9'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end