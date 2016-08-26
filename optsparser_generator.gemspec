Gem::Specification.new do |s|
  s.name     = 'optsparser_generator'
  s.version  = '2.6'
  s.summary  = 'Generates OptionParser using an OpenStruct'
  s.author   = 'Marvin Zerulla'
  s.homepage = 'https://github.com/madblobfish/optionparser-generator'
  s.license  = 'AGPL-1.0'
  s.files    = ['lib/optsparser_generator.rb']
  s.extra_rdoc_files = ['README.md', 'LICENSE.md']
  s.required_ruby_version = '>= 2.0.0'
  s.add_development_dependency 'rspec', '>= 3.5.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard', '>= 0.8'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rake', '>= 11.2.0'

  # std lib
  # s.add_runtime_dependency 'ostruct'
  # s.add_runtime_dependency 'optparse'
end
