# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git-shell/version'

Gem::Specification.new do |spec|
  spec.name          = 'git-shell'
  spec.version       = GitShell::VERSION
  spec.authors       = ['Ontohub Core Developers']
  spec.email         = ['ontohub-dev-l@ovgu.de']
  spec.summary       = 'Git shell for interaction with git clients'
  spec.description   = 'Git shell for interaction with git clients'
  spec.homepage      = 'https://github.com/ontohub/git-shell'
  spec.license       = 'GNU AFFERO GPL'

  # Prevent pushing this gem to RubyGems.org.
  unless spec.respond_to?(:metadata)
    raise "We don't want to publish this outside of the Ontohub project."
  end

  spec.test_files    = Dir['spec/**/*']
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|s|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'codecov', '~> 0.1.10'
  spec.add_development_dependency 'fuubar', '~> 2.3.0'
  spec.add_development_dependency 'pry', '~> 0.12.2'
  spec.add_development_dependency 'pry-byebug', '~> 3.7.0'
  spec.add_development_dependency 'pry-rescue', '~> 1.5.0'
  spec.add_development_dependency 'pry-stack_explorer', '~> 0.4.9.2'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rubocop', '~> 0.65.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.0'

  spec.add_dependency 'config', '>= 1.6.1', '< 1.8.0'
  spec.add_dependency 'rest-client', '~> 2.0.2'
end
