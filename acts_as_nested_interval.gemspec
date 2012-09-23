$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_nested_interval/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acts_as_nested_interval"
  s.version     = ActsAsNestedInterval::VERSION
  s.authors     = ["Nicolae Claudius", "Pythonic"]
  s.email       = ["nicolae_claudius@yahoo.com"]
  s.homepage    = "https://github.com/clyfe/acts_as_nested_interval"
  s.summary     = "Encode Trees in RDBMS using nested interval method."
  s.description = "Encode Trees in RDBMS using nested interval method for powerful querying and speedy inserts."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "pg"
end
