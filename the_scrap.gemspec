# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'the_scrap/version'

Gem::Specification.new do |spec|
  spec.name          = "the_scrap"
  spec.version       = TheScrap::VERSION
  spec.authors       = ["H.J.LeoChen"]
  spec.email         = ["hjleochen@hotmail.com"]
  spec.summary       = %q{The webpage scrapping.}
  spec.description   = %q{The webpage scrapping based Nokogiri.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "nokogiri"
end
