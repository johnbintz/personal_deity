# -*- encoding: utf-8 -*-
require File.expand_path('../lib/personal_deity/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["John Bintz"]
  gem.email         = ["john@coswellproductions.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "personal_deity"
  gem.require_paths = ["lib"]
  gem.version       = PersonalDeity::VERSION

  gem.add_dependency 'god'
  gem.add_dependency 'thin'
end
