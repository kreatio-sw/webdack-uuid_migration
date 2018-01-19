# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'webdack/uuid_migration/version'

Gem::Specification.new do |spec|
  spec.name          = "webdack-uuid_migration"
  spec.version       = Webdack::UUIDMigration::VERSION
  spec.authors       = ["Deepak Kumar"]
  spec.email         = ["deepak@kreatio.com"]
  spec.summary       = %q{Useful helpers to migrate Integer id columns to UUID in PostgreSql.}
  spec.description   = %q{Useful helpers to migrate Integer id columns to UUID in PostgreSql. Special support for primary keys.}
  spec.homepage      = "https://github.com/kreatio-sw/webdack-uuid_migration"
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pg", '<= 1.0'
  spec.add_development_dependency 'gem-release'

  spec.add_dependency 'activerecord', '>= 4.0'

  spec.has_rdoc= 'yard'
end
