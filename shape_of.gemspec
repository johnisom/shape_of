# Copyright 2021 John Isom.
# Licensed under the MIT open source license.

Gem::Specification.new do |s|
  s.name = "shape_of"
  s.version = "0.1.1"
  s.licenses = ["MIT"]
  s.summary = "A shape/type checker for Ruby objects."
  # s.description = ""
  s.authors = ["John Isom"]
  s.email = "john@johnisom.dev"
  s.files = ["lib/shape_of.rb"]
  s.homepage = "https://github.com/johnisom/shape_of"
  # s.metadata = {}
  s.add_development_dependency 'minitest', '~> 5'
  s.add_development_dependency 'minitest-reporters', '~> 1'
  # s.add_runtime_dependency
end
