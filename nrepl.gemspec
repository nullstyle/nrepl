# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nrepl/version'

Gem::Specification.new do |gem|
  gem.name          = "nrepl"
  gem.version       = Nrepl::VERSION
  gem.authors       = ["Scott Fleckenstein"]
  gem.email         = ["nullstyle@gmail.com"]
  gem.description   = %q{nrepl is a library used to connect a clojure nrepl}
  gem.summary       = %q{nrepl is a library used to connect a clojure nrepl}
  gem.homepage      = "https://github.com/nullstyle/nrepl"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency "bencode",       "~> 0.7.0"
  gem.add_dependency "retriable",     "~> 1.3.3"
  gem.add_dependency "activesupport", "~> 3.2.11"
  
  gem.add_development_dependency "pry", "~> 0.9.11.4"
end
